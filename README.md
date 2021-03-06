# osparser (oscript parser)

## Парсер встроенного языка платформы 1С:Предприятие 8

Документация: [Книга Джедая](book.md)

Установка: `opm install osparser`

Самый короткий пример без плагинов:

```bsl
#Использовать osparser

Парсер = Новый ПарсерВстроенногоЯзыка;
АСД = Парсер.Разобрать("x = x + 1;");
Сообщить(АСД.Операторы.Количество());
```

## Содержание

1. [Введение](#введение)
2. [Структура репозитория](#структура-репозитория)
3. [Принцип работы](#принцип-работы)
4. [Благодарности](#благодарности)

## Введение

Перед тем как разбираться с этим проектом, убедитесь что вы хорошо понимаете что такое AST и Visitor и что можно с их помощью делать.
Это важно, так как данная разработка предоставляет именно эти возможности. Не больше не меньше.
Вы можете писать проверки кода, компиляторы, интерпретаторы и любые другие вещи, которые можно реализовать путем обработки AST.
Сколько информации содержит AST можно увидеть тут: https://oscript-library.github.io/osparser

Общее представление можно получить в этой статье: [Зачем нужен AST](https://ps-group.github.io/compilers/ast)

Данная разработка устроена похожим образом. С поправкой на то, что это реализация без ООП на языке 1С.
После ознакомления со статьей можно сразу посмотреть [Принцип работы](#принцип-работы) внизу этой страницы.

По сути это фронтенд компилятора, а вы можете к нему писать бакенды (плагины).

Пример плагина проверяющего наличие возврата в конце функций: [ДетекторФункцийБезВозвратаВКонце](./examples/plugins/Классы/ДетекторФункцийБезВозвратаВКонце.os)

Конкретно весь код проверки выглядит так (остальное там просто интерфейс плагина):

```bsl
Процедура ПосетитьОбъявлениеМетода(ОбъявлениеМетода) Экспорт
    Перем КоличествоОператоров;
    Если ОбъявлениеМетода.Сигнатура.Тип <> Типы.ОбъявлениеСигнатурыФункции Тогда
        Возврат;
    КонецЕсли;
    КоличествоОператоров = ОбъявлениеМетода.Операторы.Количество();
    Если КоличествоОператоров = 0 Или ОбъявлениеМетода.Операторы[КоличествоОператоров - 1].Тип <> Типы.ОператорВозврат Тогда
        Текст = СтрШаблон("Последней инструкцией функции `%1()` должен быть `Возврат`""", ОбъявлениеМетода.Сигнатура.Имя);
        Ошибка(Текст, ОбъявлениеМетода.Конец);
    КонецЕсли;
КонецПроцедуры
```

Эта процедура вызывается визитером (Visitor) во время обхода AST для каждой встреченной процедуры или функции.
Суть реализации проверки: Сначала проверяется что это функция. Затем берется количество операторов в теле функции.
Если 0 или последний оператор не `Возврат`, то регистрируется ошибка.

Пример плагина средней сложности: [ДетекторНеиспользуемыхПеременных](./examples/plugins/Классы/ДетекторНеиспользуемыхПеременных.os)
 (этот код находит неиспользуемые переменные и параметры)

Пример сложного бакенда: [Компилятор](./examples/backends/Классы/Компилятор.os)
 (это генератор байткода, который работает идентично платформенному)

Пример на OneScript, демонстрирующий прогон проверок исходного кода: [test.os](./examples/test.os)

Пример на OneScript, демонстрирующий автоматическое исправление исходного кода: [test8.os](./examples/test8.os)

Пример выгрузки ошибок в [SonarQube](https://www.sonarqube.org/): [test7.os](./examples/test7.os)

## Структура репозитория

* /docs - файлы веб-страницы проекта <https://oscript-library.github.io/osparser>
* /examples - примеры
* /src - исходники парсера
* /docgen.os - скрипт, генерирующий документацию в папке /docs

## Принцип работы

Парсер разбирает переданный ему исходный код и возвращает модель этого кода в виде [абстрактного синтаксического дерева](https://ru.wikipedia.org/wiki/%D0%90%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D0%BE%D0%B5_%D1%81%D0%B8%D0%BD%D1%82%D0%B0%D0%BA%D1%81%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5_%D0%B4%D0%B5%D1%80%D0%B5%D0%B2%D0%BE). Узлы этого дерева соответствуют синтаксическим конструкциям и операторам языка. Например, конструкция `Пока <условие> Цикл <тело> КонецЦикла` представлена в дереве узлами типа `ОператорПока`, в которых условие представлено в подчиненном узле-выражении `Выражение`, а тело хранится в массиве узлов-операторов `Операторы`. Данных в дереве достаточно для полного восстановления по нему исходного кода вместе с комментариями, за исключением некоторых деталей форматирования. Порядок и подчиненность узлов в дереве в точности соответствует исходному коду. Описание узлов и элементов дерева вы можете найти на веб-странице проекта: [https://oscript-library.github.io/osparser](https://oscript-library.github.io/osparser)

После формирования дерева запускается общий механизм обхода (шаблон проектирования Visitor), который при посещении узла вызывает обработчики подписанных на этот узел плагинов. Полезная (прикладная) работа выполняется именно плагином. Это может быть сбор статистики, поиск ошибок, анализ цикломатической сложности, построение документации по коду и т.д. и т.п. Кроме того, плагин может выполнить модификацию исходного кода путем регистрации замен фрагментов текста в исходнике (например, в целях исправления ошибок или форматирования).

Состояние плагина (в переменных модуля) сохраняется между вызовами до самого конца обхода дерева, а подписки на каждый узел возможны две: перед обходом узла и после обхода. Это существенно упрощает реализацию многих алгоритмов анализа. Плюс к этому, некоторую информацию предоставляет сам механизм обхода. Например, плагинам доступна статистика по родительским узлам (количество каждого вида).

## Благодарности

Спасибо всем кто так или иначе повлиял на этот проект.
