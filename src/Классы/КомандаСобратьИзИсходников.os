///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Выполнение команды/действия в 1С:Предприятие в режиме тонкого/толстого клиента с передачей запускаемых обработок и параметров
//
// TODO добавить фичи для проверки команды
//
// Служебный модуль с набором методов работы с командами приложения
//
// Структура модуля реализована в соответствии с рекомендациями
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОписаниеПеременных

Перем Лог; // Экземпляр логгера
Перем МенеджерВерсий;

Перем ДанныеПодключения;

#КонецОбласти

#Область ОбработчикиСобытий

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ТекстОписания =
		"     Сборка cf-файла из исходников.";

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды,
		ТекстОписания);

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--src",
		"Путь к каталогу с исходниками, пример: --src=./cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-s",
		"Краткая команда 'путь к исходникам --src', пример: -s ./cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--out", 
		"Путь к файлу cf (*.cf), --out=./1Cv8.cf.
		|В пути файла можно указать шаблонную переменную $version для подстановки в нее версии конфигурации
		|Пример: --out=1Cv8_$version.cf выгрузит файл вида 1Cv8_1.2.3.4.cf");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-o",
		"Краткая команда 'Путь к файлу cf --out', пример: -o ./1Cv8.cf");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--current", "Флаг загрузки в указанную базу или -с");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-c", "Флаг загрузки в указанную базу, краткая форма от --current");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--list", "Список файлов для загрузки");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--noupdate", "Флаг обновления СonfigDumpInfo.xml");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--build-number",
		"Номер сборки для установки в последний разряд номера версии");
	ОбщиеМетоды.ДобавитьБлокIbcmd(Парсер, ОписаниеКоманды);

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры

// Выполняет логику команды
//
// Параметры:
//   ПараметрыКоманды - Соответствие - Соответствие ключей командной строки и их значений
//   ДополнительныеПараметры - Структура - дополнительные параметры (необязательно)
//
//  Возвращаемое значение:
//   Число - Код возврата команды.
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры = Неопределено) Экспорт

	Лог = ОбщиеМетоды.ЛогКоманды(ДополнительныеПараметры);

	ПутьВходящий = ОбщиеМетоды.ПолныйПуть(ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды, "-s", "--src"));
	ПутьИсходящий = ОбщиеМетоды.ПолныйПуть(ОбщиеМетоды.ПолучитьПараметры(ПараметрыКоманды, "-o", "--out"));
	СписокФайлов = ПараметрыКоманды["--list"];
	ОбновлятьФайлВерсий = НЕ ПараметрыКоманды["--noupdate"];
	ИспользоватьТекущуюИБ = ОбщиеМетоды.ЕстьФлагКоманды(ПараметрыКоманды, "-c", "--current");

	МенеджерВерсий = Новый МенеджерВерсийФайлов1С();

	НомерСборки = ПараметрыКоманды["--build-number"];
	Если ЗначениеЗаполнено(НомерСборки) Тогда

		ИзменитьНомерСборкиВИсходникахКонфигурации(ПутьВходящий, НомерСборки);

	КонецЕсли;
		
	Если ИспользоватьТекущуюИБ Тогда
		СобратьИзИсходниковТекущуюКонфигурацию(ПараметрыКоманды, ПутьВходящий, СписокФайлов, ОбновлятьФайлВерсий);
	Иначе
		СобратьИзИсходниковФайлКонфигурации(ПараметрыКоманды, 
		    ПутьВходящий, ПутьИсходящий, ОбновлятьФайлВерсий);
	КонецЕсли;

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;

КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура СобратьИзИсходниковТекущуюКонфигурацию(ПараметрыКоманды, 
	ПутьВходящий, СписокФайлов, ОбновлятьФайлВерсий)

	Лог.Информация("Запускаем сборку конфигурации из исходников в текущую ИБ...");

	МенеджерСборки = ОбщиеМетоды.ФабрикаМенеджераСборки(ПараметрыКоманды);
	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];
	МенеджерСборки.Конструктор(ДанныеПодключения, ПараметрыКоманды);
	
	Попытка
		МенеджерСборки.СобратьИзИсходниковТекущуюКонфигурацию(
				ПутьВходящий, СписокФайлов, Истина, ОбновлятьФайлВерсий);
	Исключение
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		МенеджерСборки.Деструктор();
		ВызватьИсключение ПодробноеПредставлениеОшибки(ИнформацияОбОшибке);
	КонецПопытки;

	МенеджерСборки.Деструктор();

	Лог.Информация("Сборка конфигурации из исходников в текущую ИБ завершена.");
	
КонецПроцедуры

Процедура СобратьИзИсходниковФайлКонфигурации(ПараметрыКоманды, 
    ПутьВходящий, ПутьИсходящий, ОбновлятьФайлВерсий)

	Лог.Информация("Запускаем сборку конфигурации из исходников в файл cf...");

	ОбщиеМетоды.УстановитьИспользованиеВременнойБазы(ПараметрыКоманды);

	МенеджерСборки = ОбщиеМетоды.ФабрикаМенеджераСборки(ПараметрыКоманды);
	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];

	МенеджерСборки.Конструктор(ДанныеПодключения, ПараметрыКоманды);
	КаталогВременнойИБ = МенеджерСборки.КаталогВременнойИБ();

	ПутьИсходящийСВерсией = МенеджерВерсий.ПодставитьНомерВерсии(ПутьВходящий, ПутьИсходящий);
	Попытка
		
		МенеджерСборки.СоздатьФайловуюБазу(КаталогВременнойИБ);
		МенеджерСборки.СобратьИзИсходниковТекущуюКонфигурацию(ПутьВходящий, , , ОбновлятьФайлВерсий);
		МенеджерСборки.ВыгрузитьКонфигурациюВФайл(ПутьИсходящийСВерсией);
		
	Исключение
		МенеджерСборки.Деструктор();
		ВызватьИсключение;
	КонецПопытки;

	МенеджерСборки.Деструктор();

	Лог.Информация("Сборка конфигурации из исходников в файл cf завершена.");

КонецПроцедуры

Процедура ИзменитьНомерСборкиВИсходникахКонфигурации(Знач ПутьИсходников, Знач НомерСборки)

	Лог.Информация("Изменяю номер сборки в исходниках конфигурации 1С на %1", НомерСборки);

	СтарыеВерсии = МенеджерВерсий.УстановитьНомерСборкиДляКонфигурации(ПутьИсходников, НомерСборки);

	Для каждого КлючЗначение Из СтарыеВерсии Цикл
		Лог.Информация("    Старая версия %1, файл - %2", КлючЗначение.Значение, КлючЗначение.Ключ);
	КонецЦикла;

КонецПроцедуры

#КонецОбласти
