create table person(
    national_code char(10) ,
    password text not null ,
    register_date datetime not null ,
    first_name varchar(512) not null ,
    last_name varchar(512) not null ,
    gender varchar(16) not null ,
    date_of_birth date not null ,
    disease varchar(16) not null ,
    primary key (national_code),
    constraint numeric_check check ( national_code REGEXP '^[0-9]+$' ),
    constraint length_check check ( char_length(national_code) = 10 ),
    constraint disease_check check ( disease in ('yes', 'no') ),
    constraint gender_check check ( gender in ('male', 'female') )
);

create trigger check_pass before insert on person for each row
    begin
        DECLARE dummy int;
        if char_length(new.password) < 8 then
            select 'Password length must be at least 8.' into dummy
            from information_schema.TABLES;
        elseif new.password REGEXP '^(?=.*[a-zA-Z])(?=.*[0-9])' then
            set new.password = MD5(new.password);
        else
            select 'Your password must contain at least one letter and number' into dummy
            from information_schema.TABLES;
        end if;
    end;


create table doctor(
    national_code char(10),
    ME_number char(5) unique not null ,
    primary key (national_code),
    foreign key (national_code) references person(national_code) on delete cascade on update cascade ,
    constraint numeric_check check ( ME_number REGEXP '^[0-9]+$' ),
    constraint length_check check ( char_length(ME_number) = 5 )
);

create table nurse(
    national_code char(10),
    degree varchar(32) not null ,
    nursing_code char(8) unique not null ,
    primary key (national_code),
    foreign key (national_code) references person(national_code) on delete cascade on update cascade,
    constraint degree check ( degree in ('matron', 'supervisor', 'nurse', 'paramedic') ),
    constraint numeric_check check ( nursing_code REGEXP '^[0-9]+$' ),
    constraint length_check check ( char_length(nursing_code) = 8 )
);

create table logs(
    login_time datetime,
    national_code char(10) not null,
    tag text unique not null ,
    primary key (login_time),
    foreign key (national_code) references person(national_code) on delete cascade on update cascade
);

create function sign_in(national_code char(10), password text)
    returns text
    begin
        declare result text;
        declare tag text;
        if (select count(*)
            from person
            where (national_code = person.national_code and md5(password) = person.password)) = 1 then
            set tag = md5(rand());
            insert into logs values (now(), national_code, tag);
            set result = concat('You have successfully signed in. Your tag: ', tag);
        elseif (select count(*)
                from person
                where national_code = person.national_code) = 0 then
            set result = 'Your are not registered.';
        else
            set result = 'Entered password is incorrect';
        end if;
        return result;
    end;


create table brand(
    name varchar(512),
    required_dosage int not null ,
    interval_dosage int not null ,
    registered_by char(5) not null ,
    primary key (name),
    foreign key (registered_by) references doctor(ME_number)
);

create function create_brand(name varchar(512), required_dosage int, interval_dosage int, tag text)
    returns text
    begin
        declare result text;
        declare registered_by char(5);
        select ME_number into registered_by
        from logs join doctor on logs.national_code = doctor.national_code
        where logs.tag = tag;
        if registered_by is not null then
            set result = 'The brand successfully registered.';
            insert into brand values (name, required_dosage, interval_dosage, registered_by);
        else
            set result = 'You do not have access.';
        end if;
        return result;
    end;


create table vac_center(
    name varchar(512),
    address varchar(512) not null ,
    primary key (name)
);

create function create_vac_center(name varchar(512), address varchar(512), tag text)
    returns text
    begin
        declare result text;
        declare registered_by char(5);
        select ME_number into registered_by
        from logs join doctor on logs.national_code = doctor.national_code
        where logs.tag = tag;
        if registered_by is not null then
            set result = 'The vaccination center successfully registered.';
            insert into vac_center values (name, address);
        else
            set result = 'You do not have access.';
        end if;
        return result;
    end;

create function delete_user(national_code char(10), tag text)
    returns text
    begin
        declare result text;
        declare registered_by char(5);
        select ME_number into registered_by
        from logs join doctor on logs.national_code = doctor.national_code
        where logs.tag = tag;
        if registered_by is not null then
            if (national_code in (select person.national_code from person)) then
                delete from person where person.national_code = national_code;
                set result = 'The user successfully deleted.';
            else
                set result = 'The entered national code does not registered.';
            end if;
        else
            set result = 'You do not have access.';
        end if;
        return result;
    end;


create table vial(
    brand_name varchar(512) not null ,
    serial_number varchar(512) ,
    dose_number int not null ,
    production_date date not null ,
    primary key (serial_number),
    constraint numeric_check check ( serial_number REGEXP '^[0-9]+$' ),
    foreign key (brand_name) references brand(name) on delete cascade on update cascade
);


create function create_vial(brand_name varchar(512), serial_number varchar(512), dose_number int, production_date date,
                            tag text)
    returns text
    begin
        declare result text;
        declare registered_by char(8);
        select nursing_code into registered_by
        from logs join nurse on logs.national_code = nurse.national_code
        where degree = 'matron' and logs.tag = tag;
        if registered_by is not null then
            if brand_name in (select name from brand) then
                insert into vial values (brand_name, serial_number, dose_number, production_date);
                set result = 'The vial successfully registered.';
            else
                set result = 'The entered brand does not exist';
            end if;
        else
            set result = 'You do not have access.';
        end if;
        return result;
    end;



create table injection(
    national_code char(10),
    vac_center varchar(512),
    vial_serial_number varchar(512),
    injection_date date,
    rate int,
    nurse_code char(8),
    primary key (national_code, vial_serial_number),
    foreign key (national_code) references person(national_code),
    foreign key (vial_serial_number) references vial(serial_number) ,
    foreign key (vac_center) references vac_center(name) ,
    foreign key (nurse_code) references nurse(nursing_code) ,
    constraint interval_check check ( rate >= 1 and rate <= 5 )
);


create function register_injection(national_code char(10), vac_center_name varchar(512),
                                    vial_serial_number varchar(512), tag text)
    returns text
    begin
        declare result text;
        declare registered_by char(8);
        select nursing_code into registered_by
        from logs join nurse on logs.national_code = nurse.national_code
        where logs.tag = tag;
        if registered_by is not null then
            if (national_code in (select person.national_code from person)) then
                if (vac_center_name in (select name from vac_center)) then
                    if (vial_serial_number in (select serial_number from vial)) then
                        if (select count(injection_date) from injection
                            where injection.vial_serial_number = vial_serial_number) <
                            (select dose_number from vial where vial_serial_number = vial.serial_number) then
                            insert into injection values (national_code, vac_center_name, vial_serial_number, curdate(),
                                                          null, registered_by);
                            set result = 'The injection successfully registered.';
                        else
                            set result = 'The vial doses have finished.';
                        end if;
                    else
                        set result = 'Vial does not registered.';
                    end if;
                else
                    set result = 'Vaccination center does not registered.';
                end if;
            else
                set result = 'National code does not registered.';
            end if;
        else
            set result = 'You do not have access.';
        end if;
        return result;
    end;


create procedure view_account(tag text)
    begin
        declare user char(10);
        select national_code into user from logs where logs.tag = tag;
        if user is not null then
            select national_code, register_date, first_name, last_name, gender, date_of_birth, disease
            from person
            where user = person.national_code;
        else
            select 'The entered tag is incorrect' as 'Error';
        end if;
    end;

create procedure change_pass(pass text, tag text)
    begin
        declare result text;
        declare user char(10);
        select national_code into user from logs where logs.tag = tag;
        if user is not null then
            if char_length(pass) >= 8 then
                if pass REGEXP '^(?=.*[a-zA-Z])(?=.*[0-9])' then
                    update person set person.password = md5(pass)
                    where user = person.national_code;
                    set result = 'Your password Successfully changed.';
                else
                    set result = 'your password must contain at least one letter and number.';
                end if;
            else
                set result = 'Password length must be at least 8.';
            end if;
        else
            set result = 'The entered tag is incorrect';
        end if;
        select result;
    end;


create procedure rate_vac_center(vac_center varchar(512), rate int, tag text)
    begin
        declare result text;
        declare user char(10);
        select national_code into user from logs where logs.tag = tag;
        if user is not null then
            if vac_center in (select vac_center from injection where national_code = user) then
                if exists(select * from injection
                    where national_code = user and vac_center = injection.vac_center and injection.rate is null) then
                    update injection set injection.rate = rate
                    where national_code = user and vac_center = injection.vac_center and injection.rate is null;
                    set result = 'You successfully rated.';
                else
                    set result = 'You rated this vaccination center before.';
                end if;
            else
                set result = 'You do not have an injection there.';
            end if;
        else
            set result = 'The entered tag is incorrect';
        end if;
        select result;
    end;

create procedure top5_vac_center(page int)
    begin
        declare row_index int;
        set row_index = (page - 1) * 5;
        select vac_center as 'vaccination center', coalesce(round(avg(rate), 1), 'No rate') as 'rate'
        from injection
        group by vac_center
        order by avg(rate) desc
        limit row_index, 5;
    end;


create procedure last5day_stat(page int)
    begin
        declare row_index int;
        set row_index = (page - 1) * 5;
        select injection_date 'date', count(national_code) as 'injections number'
        from injection
        group by injection_date
        order by injection_date desc
        limit row_index, 5;
    end;


create procedure vaccinated_per_brand()
    begin
        drop temporary table if exists t1;
        create temporary table t1
            select brand_name, count(distinct national_code) as brand_total
            from (vial as v1 join injection as i1 on v1.serial_number = i1.vial_serial_number)
                join brand on brand_name = brand.name
            where (select count(injection.national_code) from injection
                   where i1.national_code = injection.national_code) >= required_dosage
            group by brand_name
            order by brand_total desc;

        select 'Total' as 'brand', coalesce(sum(brand_total), 0) as 'vaccinated number'
        from t1
        union
        select *
        from t1;
    end;


create procedure top3_vac_center_per_brand(brand_name varchar(512))
    begin
        select vac_center as 'vaccination center', coalesce(round(avg(rate), 1), 'No rate') as 'rate'
        from injection join vial on injection.vial_serial_number = vial.serial_number
        where vial.brand_name = brand_name
        group by vac_center
        order by avg(rate) desc
        limit 3;
    end;


create procedure top5_vac_center_personalized(page int, tag text)
    begin
        declare row_index int;
        declare user char(10);
        declare user_brand varchar(512);
        set row_index = (page - 1) * 5;
        select national_code into user from logs where logs.tag = tag;
        if user is not null then
            select distinct brand_name into user_brand
            from injection join vial on injection.vial_serial_number = vial.serial_number
            where injection.national_code = user;

            select vac_center as 'vaccination center', coalesce(round(avg(rate), 1), 'No rate') as 'rate'
            from injection join vial on injection.vial_serial_number = vial.serial_number
            where vial.brand_name = user_brand
            group by vac_center
            order by avg(rate) desc
            limit row_index, 5;
        else
            select 'The entered tag is incorrect' as 'Error';
        end if;
    end;
