from mysql import connector
from prettytable import PrettyTable

my_db = connector.connect(host="localhost", user="root", password="", database="db_project")
my_cursor = my_db.cursor()

user_in = True
while user_in:
    print('1: sign up\n2: sign in\n3: users panel\n4: doctors panel\n5: nurses panel\n6: EXIT')
    command = input()
    if command == '1':
        print('sign up as\n1: user\n2: doctor\n3: nurse')
        command = input()
        national_code = input('Enter your national code: ')
        password = input('Enter password (password length must be at least 8 and contain both letter and number): ')
        first_name = input('Enter your first name: ')
        last_name = input('Enter your last name: ')
        gender = input('Enter your gender (male or female): ')
        date_of_birth = input('Enter your date of birth (format: YYYY-MM-DD): ')
        disease = input('Do you have special disease (yes or no): ')
        if command == '1':
            values = (national_code, password, first_name, last_name, gender, date_of_birth, disease)
            try:
                my_cursor.execute("insert into person values (%s, %s, now(), %s, %s, %s, %s, %s)", values)
                my_db.commit()
                print('You have successfully signed up. Sign in to continue.')
            except connector.Error as e:
                print(e)
        if command == '2':
            me = input('Enter your ME code: ')
            values1 = (national_code, password, first_name, last_name, gender, date_of_birth, disease)
            values2 = (national_code, me)
            try:
                my_cursor.execute("insert into person values (%s, %s, now(), %s, %s, %s, %s, %s)", values1)
                my_cursor.execute("insert into doctor values (%s, %s)", values2)
                my_db.commit()
                print('You have successfully signed up. Sign in to continue.')
            except connector.Error as e:
                print(e)
        if command == '3':
            degree = input('Enter your degree: ')
            nursing_code = input('Enter your nursing code: ')
            values1 = (national_code, password, first_name, last_name, gender, date_of_birth, disease)
            values2 = (national_code, degree, nursing_code)
            try:
                my_cursor.execute("insert into person values (%s, %s, now(), %s, %s, %s, %s, %s);", values1)
                my_cursor.execute("insert into nurse values (%s, %s, %s);", values2)
                my_db.commit()
                print('You have successfully signed up. Sign in to continue.')
            except connector.Error as e:
                print(e)
    elif command == '2':
        national_code = input('Enter your national code: ')
        password = input('Enter your password: ')
        my_cursor.execute("select sign_in(%s, %s);", (national_code, password))
        print(my_cursor.fetchone()[0])
        my_db.commit()
        input('enter any key to continue: ')
    elif command == '3':
        panel_in = True
        while panel_in:
            print('1: view account information\n2: change password\n3: rate vaccination center')
            print('4: show best vaccination centers\n5: show injection daily statistics')
            print('6: show number of vaccinated per brand\n7: show best vaccination centers per brand')
            print('8: show best vaccination centers for your next dosage\n9: EXIT users panel')
            command = input()
            if command == '1':
                tag = input('Enter your tag: ')
                my_cursor.callproc('view_account', (tag, ))
                for result in my_cursor.stored_results():
                    column_names = result.column_names
                    table = result.fetchall()
                    x = PrettyTable(column_names)
                    x.align = 'l'
                    x.add_rows(table)
                    print(x)
                my_db.commit()
                input('enter any key to continue: ')
            elif command == '2':
                tag = input('Enter your tag: ')
                password = input('Enter your new password: ')
                values = (password, tag)
                my_cursor.callproc('change_pass', values)
                for result in my_cursor.stored_results():
                    print(result.fetchone()[0])
                my_db.commit()
                input('enter any key to continue: ')
            elif command == '3':
                tag = input('Enter your tag: ')
                vac_center_name = input('Enter vaccination center name: ')
                rate = input('Enter your rate: ')
                values = (vac_center_name, rate, tag)
                try:
                    my_cursor.callproc('rate_vac_center', values)
                    for result in my_cursor.stored_results():
                        print(result.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '4':
                page = 0
                next_page = True
                while next_page:
                    page += 1
                    values = (page, )
                    my_cursor.callproc('top5_vac_center', values)
                    for result in my_cursor.stored_results():
                        column_names = result.column_names
                        table = result.fetchall()
                        x = PrettyTable(column_names)
                        x.align = 'l'
                        x.add_rows(table)
                        print(x)
                    my_db.commit()
                    print('1: next page, 2: EXIT vaccination center list')
                    if input() == '2':
                        next_page = False
            elif command == '5':
                page = 0
                next_page = True
                while next_page:
                    page += 1
                    values = (page,)
                    my_cursor.callproc('last5day_stat', values)
                    for result in my_cursor.stored_results():
                        column_names = result.column_names
                        table = result.fetchall()
                        x = PrettyTable(column_names)
                        x.align = 'l'
                        x.add_rows(table)
                        print(x)
                    my_db.commit()
                    print('1: next page, 2: EXIT injection statistics')
                    if input() == '2':
                        next_page = False
            elif command == '6':
                my_cursor.callproc('vaccinated_per_brand')
                for result in my_cursor.stored_results():
                    column_names = result.column_names
                    table = result.fetchall()
                    x = PrettyTable(column_names)
                    x.align = 'l'
                    x.add_rows(table)
                    print(x)
                my_db.commit()
                input('enter any key to continue: ')
            elif command == '7':
                brand_name = input('Enter brand name: ')
                values = (brand_name, )
                my_cursor.callproc('top3_vac_center_per_brand', values)
                for result in my_cursor.stored_results():
                    column_names = result.column_names
                    table = result.fetchall()
                    x = PrettyTable(column_names)
                    x.align = 'l'
                    x.add_rows(table)
                    print(x)
                my_db.commit()
                input('enter any key to continue: ')
            elif command == '8':
                tag = input('Enter your tag: ')
                page = 0
                next_page = True
                while next_page:
                    page += 1
                    values = (page, tag)
                    my_cursor.callproc('top5_vac_center_personalized', values)
                    for result in my_cursor.stored_results():
                        column_names = result.column_names
                        table = result.fetchall()
                        x = PrettyTable(column_names)
                        x.align = 'l'
                        x.add_rows(table)
                        print(x)
                    my_db.commit()
                    print('1: next page, 2: EXIT vaccination center list')
                    if input() == '2':
                        next_page = False
            elif command == '9':
                panel_in = False
    elif command == '4':
        panel_in = True
        while panel_in:
            print('1: register brand\n2: register vaccination center\n3: delete user\n4: EXIT doctors panel')
            command = input()
            if command == '1':
                tag = input('Enter your tag: ')
                brand_name = input('Enter brand name: ')
                required_dosage = input('Enter required dosage: ')
                interval_dosage = input('Enter interval between injections: ')
                values = (brand_name, required_dosage, interval_dosage, tag)
                try:
                    my_cursor.execute("select create_brand(%s, %s, %s, %s);", values)
                    print(my_cursor.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '2':
                tag = input('Enter your tag: ')
                vac_center_name = input('Enter vaccination center name: ')
                address = input('Enter vaccination center address: ')
                values = (vac_center_name, address, tag)
                try:
                    my_cursor.execute("select create_vac_center(%s, %s, %s);", values)
                    print(my_cursor.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '3':
                tag = input('Enter your tag: ')
                user_national_code = input("Enter user's national code: ")
                values = (user_national_code, tag)
                try:
                    my_cursor.execute("select delete_user(%s, %s);", values)
                    print(my_cursor.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '4':
                panel_in = False
    elif command == '5':
        panel_in = True
        while panel_in:
            print('1: register vial\n2: register injection\n3: EXIT nurses panel')
            command = input()
            if command == '1':
                tag = input('Enter your tag: ')
                brand_name = input('Enter brand name of vial: ')
                serial_number = input('Enter serial number of vial: ')
                dose_number = input('Enter doses number of vial: ')
                production_date = input('Enter production date of vial: ')
                values = (brand_name, serial_number, dose_number, production_date, tag)
                try:
                    my_cursor.execute("select create_vial(%s, %s, %s, %s, %s);", values)
                    print(my_cursor.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '2':
                tag = input('Enter your tag: ')
                user_national_code = input('Enter national code of user: ')
                vac_center_name = input('Enter vaccination center name: ')
                serial_number = input('Enter serial number of vial: ')
                values = (user_national_code, vac_center_name, serial_number, tag)
                try:
                    my_cursor.execute("select register_injection(%s, %s, %s, %s);", values)
                    print(my_cursor.fetchone()[0])
                    my_db.commit()
                except connector.Error as e:
                    print(e)
                input('enter any key to continue: ')
            elif command == '3':
                panel_in = False
    elif command == '6':
        user_in = False
        my_cursor.close()
        my_db.close()
