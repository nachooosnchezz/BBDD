create or replace trigger CONTROL_PRECIOS_ENTRADA
before insert on compra
for each row
declare
    -- VARIABLES QUE HAGAN FALTA
    v_ultimopreciocompra number;
begin
    select ultimopreciocompra into v_ultimopreciocompra from v_existencias where idproducto = :new.id_producto;
        
    if v_ultimopreciocompra is not null then
        if :new.precio_proveedor > v_ultimopreciocompra + 10 or :new.precio_proveedor < v_ultimopreciocompra - 10 then
            RAISE_APPLICATION_ERROR(-20200, 'PRECIOFUERADERANGO');
        end if;
    end if;
end;
/

-- PRUEBA DEL TRIGGER
declare
    id number;
begin
crear_producto( 'Pera limonera', id );
entrada_producto( id, 1, 10); -- COMPRO 1 A 10e, ADMITIDO POR SER LA PRIMERA
entrada_producto( id, 3, 20); -- COMPRO 3 A 20e, ADMITIDO
entrada_producto( id, 2, 9); -- COMPRO 2 A 9e, DEBERIA DAR ERROR
end;
/




create table T_SALDO(
    saldo number(10,2)
);


create or replace trigger TRIGGERENTRADA
after insert on compra
for each row
declare
begin
    -- Actualizamos el saldo restando el dinero gastado en la compra
    update T_SALDO set saldo = nvl(saldo, 0) - (:new.cantidad * :new.precio_proveedor);
    
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_proveedor * -1);
    end if;
end;
/

-- Creamos el trigger para la tabla venta (salida de productos)
create or replace trigger TRIGGERSALIDA
after insert on venta
for each row
declare
begin
    -- Actualizamos el saldo sumando el dinero obtenido por la venta
    update T_SALDO set saldo = nvl(saldo, 0) + (:new.cantidad * :new.precio_unidad);
    -- Si no hay ninguna fila en T_SALDO, creamos una nueva fila con el saldo actualizado
    if sql%notfound then
        insert into T_SALDO values (:new.cantidad * :new.precio_unidad);
    end if;
end;
/

