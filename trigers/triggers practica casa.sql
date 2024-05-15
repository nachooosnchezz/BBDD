
declare
    id number := 10424;
begin
    CREAR_PRODUCTO('azafran', id);
end;
/

DECLARE
    id NUMBER;
BEGIN
    CREAR_PRODUCTO('azafran', id); -- Asegúrate de que el segundo argumento sea un número.
    ENTRADA_PRODUCTO(id, 10, 1);
    SALIDA_PRODUCTO(id, 5, 2);
END;



create or replace NONEDITIONABLE trigger TRIGGERENTRADA
after insert on compra
for each row
declare
    v_saldo number;
begin
    select saldo into v_saldo from t_saldo;
    if v_saldo is null then
        update t_saldo set saldo = 0;
    end if;
    
    -- Actualizamos el saldo restando el dinero gastado en la compra
    update T_SALDO set saldo = saldo - (:new.cantidad * :new.precio_proveedor);
    dbms_output.put_line(v_saldo);
    
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    --if sql%notfound then
      --  insert into T_SALDO values (:new.cantidad * :new.precio_proveedor * -1);
    --end if;
end;
/


create or replace NONEDITIONABLE trigger TRIGGERSALIDA
after insert on venta
for each row
declare
    v_saldo number;
begin

    select saldo into v_saldo from t_saldo;
    if v_saldo is null then
        update t_saldo set saldo = 0;
    end if;
    
    -- Actualizamos el saldo sumando el dinero obtenido por la venta
    update T_SALDO set saldo = saldo + (:new.cantidad * :new.precio_unidad);
        dbms_output.put_line(v_saldo);

    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    --if sql%notfound then
      --  insert into T_SALDO values (:new.cantidad * :new.precio_unidad);
    --end if;
end;
/


create or replace NONEDITIONABLE procedure CREAR_PRODUCTO (
    p_nombreproducto IN varchar, 
    p_idproducto IN OUT number
)
AS
    v_producto productos%rowtype;
    v_existe number;
BEGIN

    select count(*) into v_existe from productos where id_producto = p_idproducto;
    
    if v_existe is not null or v_existe <> 0 then
        raise_application_error(-20002,'PRODUCTOYAEXISTE');
    elsif v_existe is null then
        p_idproducto := nuevo_id_producto.nextval;
    end if;
    
    
    -- asigno el parametro con el nuevo id al tipo de dato
    v_producto.id_producto := p_idproducto;
    -- nuevo nombre del producto 
    v_producto.nombre := p_nombreproducto ;
    -- stock como 0
    v_producto.stock := 0;

    --inserto los datos 
    insert into productos values v_producto;
END;
/

select  nuevo_id_producto.nextval from dual;

set serveroutput on;




create or replace trigger CONTROL_TRANSACCIONES_VENTAS 
before insert on venta
for each row
declare
    v_cantidad_stock NUMBER;
begin
    --verificar si hay stock suficiente para insertar la venta
    select stock into v_cantidad_stock from productos where id_producto = :new.id_producto;
    
    -- si no hay stock, salta el error ROTURADESTOCK
    if v_cantidad_stock < :new.cantidad then
        RAISE_APPLICATION_ERROR(-20001,'ROTURADESTOCK');
    end if;
    
    -- si hay stock, la venta se hace
    update productos set stock = stock - :new.cantidad where id_producto = :new.id_producto;
end;
/


create or replace trigger CONTROL_DE_ENTRADA
before insert on COMPRA
for each row
declare
    v_nombre_producto number;
begin
    -- verificar si existe
    select count(nombre) into v_nombre_producto from productos where id_producto = :new.id_producto;
    if v_nombre_producto is null or v_nombre_producto = 0 then
        -- si no existe abortar la operacion y mandar mensaje de advertencia
        RAISE_APPLICATION_ERROR(-20004,'El producto no existe');
    end if;
    
end;
/