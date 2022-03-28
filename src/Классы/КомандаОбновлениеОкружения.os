///////////////////////////////////////////////////////////////////
//
// Служебный модуль с набором методов работы с командами приложения
//
// Структура модуля реализована в соответствии с рекомендациями
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////

#Использовать logos
#Использовать v8runner
#Использовать fs

Перем Лог;
Перем КорневойПутьПроекта;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ТекстОписания =
		"     Обновление ИБ 1С.
		|";

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, ТекстОписания);

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--src", "Путь к папке исходников
	|
	|Схема работы:
	|		Указываем путь к исходникам с конфигурацией,
	|		указываем версию платформы, которую хотим использовать,
	|		и получаем по пути build\ib готовую базу для тестирования.");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--dt", "Путь к файлу с dt выгрузкой");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--dev",
		"Признак dev режима, создаем и загружаем автоматом структуру конфигурации");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--disable-support",
		"Снимает конфигурации с поддержки перед загрузкой исходников");

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--git-increment",
		СтрШаблон("Инкрменальная загрузка по git diff
		|	Схема работы
		| 		При загрузке в каталоге исходников (--src) ищется файл
		| 		%1 (необходимо добавить в .gitignore).
		| 		Если файл найден, получается дифф изменений относительно
		| 		последнего загруженного коммиту к HEAD.
		| 		Если файл не найден, происходит полная загрузка.
		| 		После загрузки создается\обновляется файл %1
		|", ИмяФайлаПредыдущегоГитКоммита()));

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--storage", "Признак обновления из хранилища");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-name", "Строка подключения к хранилищу");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-user", "Пользователь хранилища");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-pwd", "Пароль");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-ver",
		"Номер версии, по умолчанию берем последнюю");

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--v1",
		"Поддержка режима реструктуризации -v1 на сервере");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--v2",
		"Поддержка режима реструктуризации -v2 на сервере");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры // ЗарегистрироватьКоманду

// Выполняет логику команды
//
// Параметры:
//   ПараметрыКоманды - Соответствие - Соответствие ключей командной строки и их значений
//   ДополнительныеПараметры - Соответствие - дополнительные параметры (необязательно)
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры = Неопределено) Экспорт

	Лог = ДополнительныеПараметры.Лог;
	КорневойПутьПроекта = ПараметрыСистемы.КорневойПутьПроекта;

	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];

	ПараметрыХранилища = Новый Структура;
	ПараметрыХранилища.Вставить("СтрокаПодключения", ПараметрыКоманды["--storage-name"]);
	ПараметрыХранилища.Вставить("Пользователь", ПараметрыКоманды["--storage-user"]);
	ПараметрыХранилища.Вставить("Пароль", ПараметрыКоманды["--storage-pwd"]);
	ПараметрыХранилища.Вставить("Версия", ПараметрыКоманды["--storage-ver"]);
	ПараметрыХранилища.Вставить("РежимОбновления", ПараметрыКоманды["--storage"]);

	РежимыРеструктуризации = Новый Структура;
	РежимыРеструктуризации.Вставить("Первый", ПараметрыКоманды["--v1"]);
	РежимыРеструктуризации.Вставить("Второй", ПараметрыКоманды["--v2"]);

	ОбновитьБазуДанных(ПараметрыКоманды["--src"], ПараметрыКоманды["--dt"],
					ДанныеПодключения,
					ПараметрыКоманды["--uccode"],
					ПараметрыКоманды["--v8version"], ПараметрыКоманды["--dev"],
					ПараметрыХранилища, РежимыРеструктуризации,
					ПараметрыКоманды);

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;

КонецФункции

Процедура ОбновитьБазуДанных(Знач ПутьИсходников, Знач ПутьАрхиваИБ,
		Знач ДанныеПодключения,
		Знач КлючРазрешенияЗапуска, Знач ВерсияПлатформы, Знач РежимРазработчика,
		Знач ПараметрыХранилища, РежимыРеструктуризации,
		ПараметрыКоманды)

	Перем БазуСоздавали;
	БазуСоздавали = Ложь;
	ТекущаяПроцедура = "Запускаем обновление";

	СниматьСПоддержки = ПараметрыКоманды["--disable-support"];
	ИнкрементальнаяЗагрузкаGit = ПараметрыКоманды["--git-increment"];

	СтрокаПодключения = ДанныеПодключения.ПутьБазы;
	Пользователь = ДанныеПодключения.Пользователь;
	Пароль = ДанныеПодключения.Пароль;
	КодЯзыка = ДанныеПодключения.КодЯзыка;
	КодЯзыкаСеанса = ДанныеПодключения.КодЯзыкаСеанса;

	СтрокаПодключенияХранилище = ПараметрыХранилища.СтрокаПодключения;
	ПользовательХранилища = ПараметрыХранилища.Пользователь;
	ПарольХранилища = ПараметрыХранилища.Пароль;
	ВерсияХранилища = ПараметрыХранилища.Версия;
	РежимОбновленияХранилища = ПараметрыХранилища.РежимОбновления;

	Логирование.ПолучитьЛог("oscript.lib.v8runner").УстановитьУровень(Лог.Уровень());

	Если РежимРазработчика = Истина Тогда
		КаталогБазы = ОбъединитьПути(КорневойПутьПроекта, "./build/ibservice");
		СтрокаПодключения = "/F""" + КаталогБазы + """";
	КонецЕсли;

	Если ПустаяСтрока(СтрокаПодключения) Тогда
		КаталогБазы = ОбъединитьПути(КорневойПутьПроекта, ?(РежимРазработчика = Истина, "./build/ibservice", "./build/ib"));
		СтрокаПодключения = "/F""" + КаталогБазы + """";
	КонецЕсли;

	Лог.Отладка("ИнициализироватьБазуДанных СтрокаПодключения:" + СтрокаПодключения);

	Если Лев(СтрокаПодключения, 2) = "/F" Тогда
		КаталогБазы = ОбщиеМетоды.УбратьКавычкиВокругПути(Сред(СтрокаПодключения, 3, СтрДлина(СтрокаПодключения) - 2));
		ФайлБазы = Новый Файл(КаталогБазы);
		Ожидаем.Что(ФайлБазы.Существует(), ТекущаяПроцедура + " папка с базой существует").ЭтоИстина();
	КонецЕсли;

	МенеджерКонфигуратора = Новый МенеджерКонфигуратора;
	// При первичной инициализации опускаем указание пользователя и пароля, т.к. их еще нет.
	МенеджерКонфигуратора.Инициализация(
		СтрокаПодключения, "", "",
		ВерсияПлатформы, КлючРазрешенияЗапуска,
		КодЯзыка, КодЯзыкаСеанса, ПараметрыКоманды
		);

	Конфигуратор = МенеджерКонфигуратора.УправлениеКонфигуратором();

	Конфигуратор.УстановитьИмяФайлаСообщенийПлатформы(ВременныеФайлы.НовоеИмяФайла("log"));

	Конфигуратор.УстановитьКонтекст(СтрокаПодключения, "", "");
	Если Не ПустаяСтрока(ПутьАрхиваИБ) Тогда
		ПутьАрхиваИБ = Новый Файл(ОбъединитьПути(КорневойПутьПроекта, ПутьАрхиваИБ)).ПолноеИмя;
		Лог.Информация("Загружаем dt " + ПутьАрхиваИБ);
		Попытка
			Конфигуратор.УстановитьКонтекст(СтрокаПодключения, Пользователь, Пароль);
			Конфигуратор.ЗагрузитьИнформационнуюБазу(ПутьАрхиваИБ);
		Исключение
			Лог.Ошибка("Не удалось загрузить:" + ОписаниеОшибки());
		КонецПопытки;
	КонецЕсли;

	Конфигуратор.УстановитьКонтекст(СтрокаПодключения, Пользователь, Пароль);

	Если Не ПустаяСтрока(ПутьИсходников) Тогда

		Если ИнкрементальнаяЗагрузкаGit Тогда
			СписокФайлов = ПолучитьСтрокуИзмененныхФайлов(ПутьИсходников);
		Иначе
			СписокФайлов = "";
		КонецЕсли;

		Лог.Информация("Запускаю загрузку конфигурации из исходников");

		Если Не ПустаяСтрока(СписокФайлов) Тогда

			Лог.Информация(
				"Будет выполнена инкрементальная загрузка
				|Измененные файлы:
				|%1",
				СтрСоединить(СтрРазделить(СписокФайлов, ";"), Символы.ПС)
			);

		КонецЕсли;

		ПутьИсходников = Новый Файл(ОбъединитьПути(КорневойПутьПроекта, ПутьИсходников)).ПолноеИмя;

		МенеджерКонфигуратора.СобратьИзИсходниковТекущуюКонфигурацию(
			ПутьИсходников, СписокФайлов, СниматьСПоддержки);

		Если ИнкрементальнаяЗагрузкаGit Тогда
			ЗаписатьХэшПоследнегоЗагруженногоКоммита(ПутьИсходников);
		КонецЕсли;

	КонецЕсли;

	Попытка

		Если РежимОбновленияХранилища = Истина Тогда
			Лог.Информация("Обновляем из хранилища");

			МенеджерКонфигуратора.ЗапуститьОбновлениеИзХранилища(
				СтрокаПодключенияХранилище, ПользовательХранилища, ПарольХранилища,
				ВерсияХранилища);
		КонецЕсли;

		Если РежимРазработчика = Ложь Или РежимыРеструктуризации.Первый Или РежимыРеструктуризации.Второй Тогда
			ОбщиеМетоды.ОбновитьКонфигурациюБД(МенеджерКонфигуратора,
				РежимыРеструктуризации.Первый, РежимыРеструктуризации.Второй);
		КонецЕсли;

	Исключение
		МенеджерКонфигуратора.Деструктор();
		ВызватьИсключение ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
	КонецПопытки;

	МенеджерКонфигуратора.Деструктор();

КонецПроцедуры

Функция ПолучитьСтрокуИзмененныхФайлов(Знач ПутьИсходников)

	Хэш = ПолучитьХэшПоследнегоЗагруженногоКоммита(ПутьИсходников);

	Если ПустаяСтрока(Хэш) Тогда
		Возврат "";
	КонецЕсли;

	ТекущийКаталог = ТекущийКаталог();

	КоманднаяСтрока = СтрШаблон("git diff --name-only %1 HEAD", Хэш);

	Процесс = СоздатьПроцесс(КоманднаяСтрока, ТекущийКаталог, Истина, , КодировкаТекста.UTF8);
	Процесс.Запустить();

	Процесс.ОжидатьЗавершения();

	СтрокаИзмененныхФайлов = "";
	Пока Процесс.ПотокВывода.ЕстьДанные Цикл

		СтрокаВывода = Процесс.ПотокВывода.ПрочитатьСтроку();
		Если СтрНачинаетсяС(СтрокаВывода, СтрЗаменить(ПутьИсходников, "./", ""))
			И Не ФайлВСпискеИсключений(СтрокаВывода) Тогда

			СтрокаВывода = СкорректироватьПутьКИзменениюФормы(СтрокаВывода);

			ТекущаяСтрока = ОбъединитьПути(ТекущийКаталог, СтрокаВывода);
			ТекущаяСтрока = СтрЗаменить(ТекущаяСтрока, "/", ПолучитьРазделительПути());

			Если СтрНайти(СтрокаИзмененныхФайлов, ТекущаяСтрока) = 0
				И Новый Файл(ТекущаяСтрока).Существует() Тогда

				СтрокаИзмененныхФайлов = СтрокаИзмененныхФайлов + ТекущаяСтрока + ";";

			КонецЕсли;

		КонецЕсли;

	КонецЦикла;

	Если ЗначениеЗаполнено(СтрокаИзмененныхФайлов) Тогда
		СтрокаИзмененныхФайлов = Лев(СтрокаИзмененныхФайлов, СтрДлина(СтрокаИзмененныхФайлов) - 1);
	КонецЕсли;

	Возврат СтрокаИзмененныхФайлов;

КонецФункции

Функция ПолучитьХэшПоследнегоЗагруженногоКоммита(Знач ПутьИсходников)

	ИмяФайла = ФайлПредыдущегоГитКоммита(ПутьИсходников).ПолноеИмя;

	Если Не ФС.ФайлСуществует(ИмяФайла) Тогда
		Возврат "";
	КонецЕсли;

	ЧтениеТекста = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8NoBOM);
	Хэш = ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();

	Возврат СокрЛП(Хэш);

КонецФункции

Процедура ЗаписатьХэшПоследнегоЗагруженногоКоммита(Знач ПутьИсходников)

	ИмяФайла = ФайлПредыдущегоГитКоммита(ПутьИсходников).ПолноеИмя;

	ТекущийКаталог = ТекущийКаталог();

	КоманднаяСтрока = "git rev-parse --short HEAD";

	Процесс = СоздатьПроцесс(КоманднаяСтрока, ТекущийКаталог, Истина, , КодировкаТекста.UTF8);
	Процесс.Запустить();

	Процесс.ОжидатьЗавершения();

	Если Процесс.ПотокВывода.ЕстьДанные Тогда

		Хэш = Процесс.ПотокВывода.ПрочитатьСтроку();

		ЗаписьТекста = Новый ЗаписьТекста(ИмяФайла, КодировкаТекста.UTF8NoBOM);
		ЗаписьТекста.Записать(Хэш);
		ЗаписьТекста.Закрыть();

	КонецЕсли;

КонецПроцедуры

Функция СкорректироватьПутьКИзменениюФормы(СтрокаИзмененныхФайлов)

	Паттерн = "(.*Forms\/.*)\/Ext.*";

	РегулярноеВыражение = Новый РегулярноеВыражение(Паттерн);

	КоллекцияСовпаденийРегулярногоВыражения = РегулярноеВыражение.НайтиСовпадения(СтрокаИзмененныхФайлов);

	Если КоллекцияСовпаденийРегулярногоВыражения.Количество() = 1
		И КоллекцияСовпаденийРегулярногоВыражения[0].Группы.Количество() = 2 Тогда

		Возврат РегулярноеВыражение.Заменить(СтрокаИзмененныхФайлов, "$1.xml");

	КонецЕсли;

	Возврат СтрокаИзмененныхФайлов;
КонецФункции

Функция ФайлВСпискеИсключений(ПутьКФайлу)

	Возврат СтрЗаканчиваетсяНа(ПутьКФайлу, "ConfigDumpInfo.xml")
		Или СтрЗаканчиваетсяНа(ПутьКФайлу, "AUTHORS")
		Или СтрЗаканчиваетсяНа(ПутьКФайлу, "VERSION");

КонецФункции

Функция ФайлПредыдущегоГитКоммита(Знач ПутьИсходников)

	Возврат Новый Файл(ОбъединитьПути(КорневойПутьПроекта, ПутьИсходников, ИмяФайлаПредыдущегоГитКоммита()));

КонецФункции

Функция ИмяФайлаПредыдущегоГитКоммита()
	Возврат "lastUploadedCommit.txt";
КонецФункции
