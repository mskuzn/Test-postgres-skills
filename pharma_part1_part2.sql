--part1
--не совсем понял, что такое рецептурность, поэтому добавил её как самостоятельную сущность, независимую от самого товара
--поскольку имя товара должно быть уникальным, не может быть разной рецептурности для одинаковых имён товаров
--поскольку primary key не может быть null, нельзя сделать одновременно ссылку и необязательность этого параметра. 
--Защита от некорректных рецептурностей только на уровне процедуры.
create schema pharma;

create table pharma.prod_types (
  id bigserial,
  prod_type varchar unique not null check (prod_type != '') primary key
);

create table pharma.locations (
  id bigserial,
  location varchar unique not null check (location != '') primary key
);

create table pharma.pharmacies_forms (
  id bigserial,
  pharmacy_form varchar unique not null check (pharmacy_form != '') primary key
);

CREATE TABLE pharma.precriptions (
  id bigserial,
  precription varchar --primary key
);
--insert into pharma.precriptions (precription) values ('');

create table pharma.products (
  id bigserial,
  name varchar unique not null check (name != '') primary key,
  is_vital bool not null,
  prod_type varchar references pharma.prod_types(prod_type),
  precription text --references pharma.precriptions(precription)
);

create table pharma.pharmacies (
  id bigserial,
  name varchar not null check (name != '') primary key,
  location_id bigint,
  location varchar references pharma.locations(location),
  form_id bigint not null,
  pharmacy_form varchar references pharma.pharmacies_forms(pharmacy_form) 
);

create table pharma.sales (
  id bigserial,
  time_sale timestamp with time zone not null,
  pharmacy_id bigint not null,
  pharmacy_name varchar not null check (pharmacy_name != ''),
  product_id bigint not null,
  product_name varchar not null check (product_name != ''),
  num_packaging bigint not null check (num_packaging != 0),
  price numeric check (price > 0)
);

--в процессе развития проекта, роста количества данных могут быть добавлены другие индексы в зависимости от количчества тех или иных запросов.
create index products_name_idx on pharma.products (name);
create index pharmacies_name_idx on pharma.pharmacies (name);
create index sales_pharmacy_name_idx on pharma.sales (pharmacy_name);
create index sales_product_name_idx on pharma.sales (product_name);

create index products_id_idx on pharma.products (id);
create index pharmacies_id_idx on pharma.pharmacies (id);
create index sales_pharmacy_id_idx on pharma.sales (pharmacy_id);
create index sales_product_id_idx on pharma.sales (product_id);


/*drop table if exists
  pharma.pharmacies,
  pharma.products,
  pharma.sales,
  pharma.locations,
  pharma.pharmacies_forms,
  pharma.prod_types,
  pharma.precriptions
;*/

--part2
create or replace function pharma.add_product_type(prod_type varchar) RETURNS varchar AS $$
DECLARE
  prod_type varchar = $1;
BEGIN
 insert into pharma.prod_types (prod_type) values (prod_type);

return 'OK -' || prod_type ;
END; $$
language plpgsql;

create or replace function pharma.add_precription(precription text) RETURNS varchar AS $$
DECLARE
  precription varchar = $1;
BEGIN
 insert into pharma.precriptions (precription) values (precription);
 return '-' || 'OK' ;
END; $$
language plpgsql;

--##################
create or replace function pharma.add_product(name varchar, is_vital bool, prod_type varchar, precription text) RETURNS varchar AS $$
DECLARE 

  name varchar  =$1;
  is_vital bool = $2;
  prod_type varchar = $3;
  precription text = $4;
  result varchar;
  
  is_unic_prod_name bool;
  is_null_or_empty_prod_name bool;  
  is_exists_prod_type bool;
  is_null_or_empty_prod_type bool;
  
  is_exists_precription bool;
  is_null_or_empty_precription bool;


BEGIN
execute 'select count(*) = 0 from pharma.products where name = $1' into is_unic_prod_name USING name;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_prod_name USING name;

execute 'select exists(select prod_type from pharma.prod_types where prod_type = $1)' into is_exists_prod_type USING prod_type;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_prod_type USING prod_type;

execute 'select exists(select precription from pharma.precriptions where precription = $1)' into is_exists_precription USING precription;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_precription USING precription;

 case
   when not is_unic_prod_name then  result= 'Ошибка: такое имя товара уже существует! ';
   when is_null_or_empty_prod_name then  result= 'Ошибка: Имя товара не должно быть пустым! ';
   when not is_exists_prod_type then  result= 'Ошибка: Сначала заведите соответствующий тип продукта! ';
   when is_null_or_empty_prod_type then  result= 'Ошибка: Тип продукта не может быть пустым! ';
   when not (is_exists_precription or is_null_or_empty_precription) then result= 'Ошибка: Заведите соответствующую рецептурность или оставьте её пустой! ';
   else
   result = 'Проверка данных пройдена! Добавлено: ' || name;
   insert into pharma.products (name, is_vital, prod_type, precription) values (name, is_vital, prod_type, precription);

 end case;
 return result;
END; $$
language plpgsql;
--##################
create or replace function pharma.update_product(name varchar, is_vital bool, prod_type varchar, precription text) RETURNS varchar AS $$
DECLARE 

  name varchar  =$1;
  is_vital bool = $2;
  prod_type varchar = $3;
  precription text = $4;
  result varchar;
  
  is_unic_prod_name bool;
  is_null_or_empty_prod_name bool;  
  is_exists_prod_type bool;
  is_null_or_empty_prod_type bool;
  
  is_exists_precription bool;
  is_null_or_empty_precription bool;


BEGIN
execute 'select count(*) = 0 from pharma.products where name = $1' into is_unic_prod_name USING name;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_prod_name USING name;

execute 'select exists(select prod_type from pharma.prod_types where prod_type = $1)' into is_exists_prod_type USING prod_type;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_prod_type USING prod_type;

execute 'select exists(select precription from pharma.precriptions where precription = $1)' into is_exists_precription USING precription;
execute 'select $1 is null or $1 = ''''' into is_null_or_empty_precription USING precription;

 case
   when is_unic_prod_name then  result= 'Ошибка: Невозможно исправить несуществующий товар! ';
   when is_null_or_empty_prod_name then  result= 'Ошибка: Имя товара не должно быть пустым! ';
   when not is_exists_prod_type then  result= 'Ошибка: Сначала заведите соответствующий тип продукта! ';
   when is_null_or_empty_prod_type then  result= 'Ошибка: Тип продукта не может быть пустым! ';
   when not (is_exists_precription or is_null_or_empty_precription) then result= 'Ошибка: Заведите соответствующую рецептурность или оставьте её пустой! ';
   else
   result = 'Проверка данных пройдена! Обновлено: ' || name;
   execute 'update pharma.products set is_vital = $2,prod_type = $3,precription = $4 where name = $1' USING name,is_vital,prod_type,precription;

 end case;
 return result;
END; $$
language plpgsql;
--#########################

create or replace function pharma.delete_product(name varchar) RETURNS varchar AS $$
DECLARE 

  name varchar  =$1;
  result varchar;
  
  is_unic_prod_name bool;


BEGIN
execute 'select count(*) = 0 from pharma.products where name = $1' into is_unic_prod_name USING name;

 case
   when is_unic_prod_name then  result= 'Ошибка: Невозможно удалить несуществующий товар! ';
   else
   result = 'Удалено: ' || name;
   execute 'delete from pharma.products where name = $1' USING name;

 end case;
 return result;
END; $$
language plpgsql;
--#########################
--#testing#
/*
select pharma.add_product_type('таблетки');
select pharma.add_precription('Корень солодки, голова селёдки');

select pharma.add_product('барбитол',true, 'таблетки','Корень солодки, голова селёдки');
select pharma.add_product('гелетропозол',true, 'таблетки','');

select pharma.update_product('парацитофлекс',false, 'таблетки','');
select pharma.delete_product('гелетропозол');
insert into pharma.products (name, is_vital, prod_type, precription) values ('барбитол',true, 'таблетки','Корень солодки, голова селёдки');
select * from pharma.products;
*/
/*
truncate table   
--  pharma.pharmacies,
  pharma.products--,
--  pharma.sales,
--  pharma.locations,
--  pharma.pharmacies_forms,
--  pharma.prod_types
;
*/


--*/

