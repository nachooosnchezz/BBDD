select * from empleados ;
select * from pedidos ;
select * from clientes;
select * from productos;


--1.

insert into pedidos (codigopedido, codigocliente, fechapedido, fechaesperada, estado) select '1000' || codigocliente, codigocliente, sysdate, sysdate+7, 'Pendiente' from clientes;
update productos set cantidadenstock = cantidadenstock - 36 where codigoproducto LIKE 'AR-001';
insert into detallepedidos (codigopedido, codigoproducto, cantidad, preciounidad,numerolinea ) select '1000' || codigocliente, 'AR-001', 1, 0, 1 from clientes;

rollback;


--2.

update clientes set telefono = 
case 
    when
        telefono like '6%'or telefono like '9%' then '+34 ' || telefono
    when telefono like '34%' then '+' || telefono 
    else telefono
end;

update clientes set fax = 
case
    when fax like '6%' or fax like '9%' then '+34 ' || fax
    when fax like '34%' then '+' || fax 
    else fax
end;


-- 3.

update empleados set email =
case email
    when ;
    
    select (CONCAT (SUBSTR(lower(nombre),0,1), SUBSTR(lower(apellido1),0,1))) ||  (CONCAT (codigoempleado, '@jardineria.com')) from empleados ;
    
    to 
--4.

commit;

select * from productos where dimensiones like '__/__';

update productos set dimensiones = (select substr(dimensiones,0,1) * substr(dimensiones,4,2) from productos) where dimensiones like '__/__';


select substr(dimensiones,0,1)  * substr(dimensiones,4,2) from productos where dimensiones like '__/__';
select from productos where dimensiones like '__/__';


* 








