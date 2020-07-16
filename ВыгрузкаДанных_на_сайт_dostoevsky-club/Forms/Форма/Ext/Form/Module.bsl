﻿
&НаСервере
Функция ВыгрузитьНаСервере()
	
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект"); 
	РезультатВыгрузки = ОбработкаОбъект.Выгрузить();
		
	Возврат РезультатВыгрузки; 
	
КонецФункции

&НаКлиенте
Процедура Выгрузить(Команда)
	
	РезультатВыгрузки = ВыгрузитьНаСервере();
	Если РезультатВыгрузки.Успешно Тогда
        ТекстСообщения = "Успешно!";
	Иначе
		ТекстСообщения = СтрШаблон("Ошибка выгрузки данных %1",РезультатВыгрузки.ОписаниеОшибки);
	КонецЕсли; 
	
	ОбщегоНазначенияКлиент.СообщитьПользователю(ТекстСообщения);
	Если РезультатВыгрузки.Свойство("Данные") Тогда
		Для каждого ДанныеВыгрузки Из РезультатВыгрузки.Данные Цикл
			ОбщегоНазначенияКлиент.СообщитьПользователю(СтрШаблон("%1 : %2",ДанныеВыгрузки.Ключ, ДанныеВыгрузки.Значение));		
		КонецЦикла; 
	КонецЕсли;	
	
КонецПроцедуры

&НаСервере
Функция ВыгрузитьСувенирыНаСервере()
	
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект"); 
	РезультатВыгрузки = ОбработкаОбъект.ВыгрузитьСувениры();
		
	Возврат РезультатВыгрузки; 
	
КонецФункции

&НаКлиенте
Процедура ВыгрузитьСувениры(Команда)
	
	РезультатВыгрузки = ВыгрузитьСувенирыНаСервере();
	Если РезультатВыгрузки.Успешно Тогда
        ТекстСообщения = "Успешно!";
	Иначе
		ТекстСообщения = СтрШаблон("Ошибка выгрузки данных %1",РезультатВыгрузки.ОписаниеОшибки);
	КонецЕсли; 
	
	ОбщегоНазначенияКлиент.СообщитьПользователю(ТекстСообщения);
	Если РезультатВыгрузки.Свойство("Данные") Тогда
		Для каждого ДанныеВыгрузки Из РезультатВыгрузки.Данные Цикл
			ОбщегоНазначенияКлиент.СообщитьПользователю(СтрШаблон("%1 : %2",ДанныеВыгрузки.Ключ, ДанныеВыгрузки.Значение));		
		КонецЦикла; 
	КонецЕсли;	

КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	ОтветСервера = ОбработкаОбъект.ЗагрузитьНастройки();
	Если ОтветСервера.Успешно Тогда
		Если ТипЗнч(ОтветСервера.Данные)=Тип("Структура") Тогда
			ЗаполнитьЗначенияСвойств(ЭтаФорма, ОтветСервера.Данные);
		КонецЕсли;
	КонецЕсли; 
	
КонецПроцедуры

&НаСервере
Функция СтруктураНастроек()
	
	СтруктураПараметров = Новый Структура;
	
	Если ВключаяОсновные Тогда
		Для каждого ЭлементФормы Из Элементы Цикл
			Если ТипЗнч(ЭлементФормы) = Тип("ПолеФормы") Тогда
				Имя = ЭлементФормы.ПутьКДанным; 
				ПозицияТочки = СтрНайти(Имя,".");
				Если ПозицияТочки > 0 Тогда
					Имя = Сред(Имя,ПозицияТочки + 1);
				КонецЕсли; 
				СтруктураПараметров.Вставить(Имя,Вычислить(ЭлементФормы.ПутьКДанным));		
			КонецЕсли; 	
		КонецЦикла; 
	Иначе
		СтруктураПараметров.Вставить("АдресРесурса", АдресРесурса);
		СтруктураПараметров.Вставить("Логин", Логин);
		СтруктураПараметров.Вставить("Пароль", Пароль);
		СтруктураПараметров.Вставить("РазмерПакета", РазмерПакета);
		СтруктураПараметров.Вставить("ПоследнийВыгруженныйОбъект", ПоследнийВыгруженныйОбъект);
		СтруктураПараметров.Вставить("ДатаПоследнейВыгрузки", ДатаПоследнейВыгрузки);		
		СтруктураПараметров.Вставить("ПоследнийВыгруженныйОбъектСувениры", ПоследнийВыгруженныйОбъектСувениры);
		СтруктураПараметров.Вставить("ДатаПоследнейВыгрузкиСувениры", ДатаПоследнейВыгрузкиСувениры);		
		СтруктураПараметров.Вставить("КаталогЖурналаВыгрузки", КаталогЖурналаВыгрузки);
		СтруктураПараметров.Вставить("ВестиЖурналВыгрузки", ВестиЖурналВыгрузки);		
		СтруктураПараметров.Вставить("МаксимальныйРазмерЖурнала", МаксимальныйРазмерЖурнала);		
	КонецЕсли; 
	
	Возврат СтруктураПараметров;
	
КонецФункции
 

&НаСервере
Процедура СохранитьНастройкиНаСервере()
	
	СтруктураПараметров = СтруктураНастроек();
	
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	ОтветСервера = ОбработкаОбъект.СохранитьНастройки(СтруктураПараметров);
	Если ОтветСервера.Успешно Тогда
        ТекстСообщения = "Успешно!";
	Иначе
		ТекстСообщения = СтрШаблон("Ошибка сохранения параметров %1",ОтветСервера.ОписаниеОшибки);
	КонецЕсли; 
	
	ОбщегоНазначения.СообщитьПользователю(ТекстСообщения);

	
КонецПроцедуры

&НаКлиенте
Процедура СохранитьНастройки(Команда)
	СохранитьНастройкиНаСервере();
КонецПроцедуры


&НаКлиенте
Процедура КаталогВыгрузкиНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	
	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.ВыборКаталога);
	Диалог.МножественныйВыбор = Ложь;
	ОписаниеОповещения = Новый ОписаниеОповещения("ВыбратьКаталогПриОкончанииВыбора", ЭтотОбъект, "КаталогВыгрузки");

	Диалог.Показать(ОписаниеОповещения);
	
КонецПроцедуры

&НаКлиенте
Процедура ВыбратьКаталогПриОкончанииВыбора(МассивКаталогов, ИмяПеременнойСКаталогом) Экспорт
	
	ЭтотОбъект[ИмяПеременнойСКаталогом] = 
		?(МассивКаталогов = Неопределено Или МассивКаталогов.Количество() = 0,
			"", 
			МассивКаталогов[0]);
		
КонецПроцедуры


&НаСервере
Процедура ВыгрузитьКартинкиНаСервере()
	
	ОбработкаОбъект = РеквизитФормыВЗначение("Объект");
	ОтветСервера = ОбработкаОбъект.ВыгрузитьКартинки(КаталогВыгрузки, Номеклатура);
	Если ОтветСервера.Успешно Тогда
        ТекстСообщения = "Успешно!";
	Иначе
		ТекстСообщения = СтрШаблон("Ошибка выгрузки картинок %1",ОтветСервера.ОписаниеОшибки);
	КонецЕсли; 
	
	ОбщегоНазначения.СообщитьПользователю(ТекстСообщения);

КонецПроцедуры


&НаКлиенте
Процедура ВыгрузитьКартинки(Команда)
	ВыгрузитьКартинкиНаСервере();
КонецПроцедуры


&НаКлиенте
Процедура КаталогЖурналаВыгрузкиНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	
	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.ВыборКаталога);
	Диалог.МножественныйВыбор = Ложь;
	ОписаниеОповещения = Новый ОписаниеОповещения("ВыбратьКаталогПриОкончанииВыбора", ЭтотОбъект, "КаталогЖурналаВыгрузки");

	Диалог.Показать(ОписаниеОповещения);

КонецПроцедуры

