                                --2.comercial.sql

-- empleados de mayor rango en madrid, que no tienen jefe en madrid. 
select codigoempleado from empleados where codigojefe in(
    select codigojefe as NoEnMadrid from empleados where codigooficina not like 'MAD%' group by codigojefe
    ) 
and codigooficina like 'MAD%' ;


-- el de mayor rango es el rep de pepegardens
update clientes set codigoempleadorepventas = (
    select codigoempleado from empleados where codigojefe in (
        select codigojefe as NoEnMadrid from empleados where codigooficina not like 'MAD%' group by codigojefe
        ) 
        and codigooficina like 'MAD%'
    ) 
where codigocliente like 39; 


                                    -- 2.rrhh.sql

-- crear a manolo bombo como nuevo jefe de madrid. 

-- Remplazar al codigoempleado 7 a BCN
update empleados set codigooficina = 'BCN-ES' where codigoempleado like '7';

-- cambiar el codigojefe de los empleados al de manolo bombo
update empleados set codigojefe = (
    select codigoempleado from empleados where codigojefe in (
        select codigojefe as NoEnMadrid from empleados where codigooficina not like 'MAD%'
        group by codigojefe
    )
    and codigooficina like 'MAD%'
) 
where codigooficina like 'MAD%' and codigoempleado not like(
    select codigoempleado from empleados where codigojefe in (
        select codigojefe as NoEnMadrid from empleados where codigooficina not like 'MAD%' group by codigojefe
        ) 
    and codigooficina like 'MAD%' 
);

                                -- 3.comercial.sql
                                
-- cuantas ajedreas
select * from productos where nombre like ('%jedrea');
-- pedido para pepe gardens
update 