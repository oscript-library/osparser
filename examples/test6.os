// пример работы с параметрами плагинов

#Использовать osparser
#Использовать "./plugins"

Исходник = "x = 1;";

ПлагинСПараметром = Новый ПлагинСПараметром;

Плагины = Новый Массив;
Плагины.Добавить(ПлагинСПараметром);

ЧтениеJSON = Новый ЧтениеJSON;
ЧтениеJSON.ОткрытьФайл(".\param.json", "UTF-8");
ПараметрыПлагина = ПрочитатьJSON(ЧтениеJSON);

ПараметрыПлагинов = Новый Соответствие;
ПараметрыПлагинов[ПлагинСПараметром] = ПараметрыПлагина;

Парсер = Новый ПарсерВстроенногоЯзыка;

Результаты = Парсер.Пуск(Исходник, Плагины, ПараметрыПлагинов);
Сообщить(СтрСоединить(Результаты));
