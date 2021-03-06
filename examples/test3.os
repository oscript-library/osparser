
#Использовать osparser
#Использовать "./backends"

ЧтениеТекста = Новый ЧтениеТекста("..\src\Классы\ПарсерВстроенногоЯзыка.os");
Исходник = ЧтениеТекста.Прочитать();

Парсер = Новый ПарсерВстроенногоЯзыка;
АСД = Парсер.Разобрать(Исходник);

Компилятор = Новый Компилятор;
Байткод = Компилятор.Посетить(Парсер, АСД);

Сообщить(Байткод);