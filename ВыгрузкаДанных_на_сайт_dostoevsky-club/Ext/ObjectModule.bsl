﻿
Функция ОтправитьPOSTЗапрос(АдресСервера, ИмяМетода, Заголовки, ТелоЗапроса)

	СтруктураURL = ПолучениеФайловИзИнтернетаКлиентСервер.РазделитьURL(АдресСервера);
			
	HTTPЗапрос = Новый HTTPЗапрос(ИмяМетода, Заголовки);
	HTTPЗапрос.УстановитьТелоИзСтроки(ТелоЗапроса,КодировкаТекста.UTF8,ИспользованиеByteOrderMark.НеИспользовать);
	
	ЗащищенноеСоединение = Неопределено;
	Протокол = СтруктураURL.Протокол;
			
	Если (Протокол = "https" Или Протокол = "ftps") И ЗащищенноеСоединение = Неопределено Тогда
		ЗащищенноеСоединение = Истина;
	КонецЕсли;
		
	Если ЗащищенноеСоединение = Истина Тогда
		ЗащищенноеСоединение = ОбщегоНазначенияКлиентСервер.НовоеЗащищенноеСоединение();
	ИначеЕсли ЗащищенноеСоединение = Ложь Тогда
		ЗащищенноеСоединение = Неопределено;
	КонецЕсли;
		
	ПроксиСервер = Новый ИнтернетПрокси(Истина);	 
			
	HTTPСоединение = Новый HTTPСоединение(СтруктураURL.ИмяСервера,,,,ПроксиСервер,180,ЗащищенноеСоединение); 
	HTTPОтвет = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
	
	ОтветСервера =  HTTPОтвет.ПолучитьТелоКакСтроку();	
	Если HTTPОтвет.КодСостояния <> 200 Тогда			
		ВызватьИсключение СтрШаблон("Ошибка выполнения запроса. Код состояния сервера %1, тело ответа %2",
							HTTPОтвет.КодСостояния, ОтветСервера);	
	КонецЕсли;	
			
    ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(ОтветСервера);
	ДанныеСервераJSON = ПрочитатьJSON(ЧтениеJSON);
	ЧтениеJSON.Закрыть();

	Возврат ДанныеСервераJSON;
	
КонецФункции // ОтправитьPOSTЗапрос()

Функция ДанныеВJSON(Данные)

	ЗаписьJSON = Новый ЗаписьJSON();
	ЗаписьJSON.УстановитьСтроку();
	ЗаписьJSON.ПроверятьСтруктуру = Истина;
		
	ЗаписатьJSON(ЗаписьJSON, Данные);
	СтрокаJSON = ЗаписьJSON.Закрыть();

	Возврат СтрокаJSON;

КонецФункции // ДанныеВJSON()
 
Функция ОтправитьДанныеНаСайт(Настройки, ДанныеДляОтправки)
	
	МетодыСервера = Новый Структура;
	МетодыСервера.Вставить("ПолучитьТокенАвторизации","/api/v1/auth/token/");
	МетодыСервера.Вставить("ОбновитьТокенАвторизации","/api/v1/auth/token-refresh/");
	МетодыСервера.Вставить("ЗагрузитьДанныеОТоварах","/api/v1/exchange/upload-catalogue/");
	
	Заголовки = Новый Соответствие();
	Заголовки.Вставить("Content-type", "application/json; charset=UTF-8");
		
	Попытка
		
	    ПараметрыАвторизации = Настройки;
		АдресСервера = ПараметрыАвторизации.АдресРесурса;
		Результат = СтруктураСообщенияОбОшибке();
		
		// получить токен
		ДанныеАвторизации = Новый Структура;
		ДанныеАвторизации.Вставить("email",ПараметрыАвторизации.Логин);
		ДанныеАвторизации.Вставить("password",ПараметрыАвторизации.Пароль);
		ТелоЗапросаJSON = ДанныеВJSON(ДанныеАвторизации);
		ДанныеОтСервера = ОтправитьPOSTЗапрос(АдресСервера, МетодыСервера.ПолучитьТокенАвторизации, 
					Заголовки, ТелоЗапросаJSON);
					
		Заголовки.Вставить("Authorization",СтрШаблон("jwt %1",ДанныеОтСервера.access));
		
		// отправить данные
		ДанныеОтСервера = ОтправитьPOSTЗапрос(АдресСервера, МетодыСервера.ЗагрузитьДанныеОТоварах, 
					Заголовки, ДанныеДляОтправки);
		
		
		// прочитать ответ                                                             
		Результат.Успешно = Истина;
		Результат.ОписаниеОшибки = "";
		Результат.Вставить("Данные",ДанныеОтСервера);
		
	Исключение
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ТекстСообщения = НСтр("ru = 'Ошибка выгрузки данных на сайт: %1'");
		ТекстСообщения = СтрШаблон(ТекстСообщения,КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		Результат.Успешно = Ложь;
		Результат.ОписаниеОшибки = ТекстСообщения;	
	КонецПопытки;

	Возврат Результат;
	
КонецФункции
 
Функция Выгрузить() Экспорт
	
	// получить прараметры соединения
	Результат = ЗагрузитьНастройки();
	Если Не Результат.Успешно Тогда
		Возврат Результат;	
	КонецЕсли; 

	Попытка
		
		Настройки = Результат.Данные;
		Если Настройки.Свойство("ПоследнийВыгруженныйОбъект") Тогда
			ПоследнийВыгруженныйОбъект = Настройки.ПоследнийВыгруженныйОбъект;
		Иначе
			ПоследнийВыгруженныйОбъект = Справочники.Номенклатура.ПустаяСсылка();
			Настройки.Вставить("ПоследнийВыгруженныйОбъект",ПоследнийВыгруженныйОбъект);
		КонецЕсли; 
		
		Если Настройки.Свойство("РазмерПакета") Тогда
			РазмерПакета = Настройки.РазмерПакета;
		Иначе
			РазмерПакета = 0;
			Настройки.Вставить("РазмерПакета",РазмерПакета);			
		КонецЕсли;
		
		Если Настройки.Свойство("ДатаПоследнейВыгрузки") Тогда
			ДатаПоследнейВыгрузки = Настройки.ДатаПоследнейВыгрузки;
		Иначе
			ДатаПоследнейВыгрузки = '00010101';
			Настройки.Вставить("ДатаПоследнейВыгрузки",ДатаПоследнейВыгрузки);						
		КонецЕсли; 
		
		ЗаполнитьЗначенияСвойств(ЭтотОбъект,Настройки);
		
		Если Не ЗначениеЗаполнено(ПоследнийВыгруженныйОбъект) Тогда
			Если ДатаПоследнейВыгрузки >= НачалоДня(ТекущаяДатаСеанса()) Тогда
				// Выгрузка сегодня уже была
				Результат = СтруктураСообщенияОбОшибке();
				Результат.Успешно = Истина;
				Возврат Результат;
			КонецЕсли; 	
		КонецЕсли; 
		
		Запрос = Новый Запрос;
		Запрос.Текст = "ВЫБРАТЬ РАЗЛИЧНЫЕ
		               |	НоменклатураСпр.Ссылка КАК Guid,
		               |	НоменклатураСпр.Наименование КАК Наименование,
		               |	НоменклатураСпр.Артикул КАК Артикул,
		               |	ЕСТЬNULL(ЦеныНоменклатурыСрезПоследних.Цена, 0) КАК Цена,
		               |	ЕСТЬNULL(ЦеныНоменклатурыСрезПоследних1.Цена, 0) КАК ЦенаСоСкидкой,
		               |	НоменклатураСпр.Производитель КАК Производитель,
		               |	НоменклатураСпр.Описание КАК Описание,
		               |	ЕСТЬNULL(Значение1.Значение.Наименование, ""null"") КАК ISBN,
		               |	ЕСТЬNULL(Значение2.Значение.Ссылка, ""null"") КАК НазваниеСерииПродукции,
		               |	ЕСТЬNULL(Значение3.Значение, ""null"") КАК Авторы,
		               |	ЕСТЬNULL(Значение4.Значение.Наименование, ""null"") КАК НаименованиеДляСайта,
		               |	ЕСТЬNULL(Значение5.Значение, ""null"") КАК ТипТовара,
		               |	ЕСТЬNULL(Значение6.Значение, ""null"") КАК КоличествоСтраниц,
		               |	ЕСТЬNULL(Значение7.Значение, ""null"") КАК Измерение1,
		               |	ЕСТЬNULL(Значение8.Значение, ""null"") КАК Измерение2,
		               |	ЕСТЬNULL(Значение9.Значение, ""null"") КАК Измерение3,
		               |	ЕСТЬNULL(Значение10.Значение, ""null"") КАК Вес,
		               |	ЕСТЬNULL(Значение11.Значение, ""null"") КАК ГодВыпуска,
		               |	ЕСТЬNULL(Значение12.Значение.Ссылка, ""null"") КАК СтранаПроизводитель,
		               |	ЕСТЬNULL(Значение13.Значение, ""null"") КАК Жанр,
		               |	ЕСТЬNULL(Значение14.Значение, ""null"") КАК ВозрастноеОграничение,
		               |	ЕСТЬNULL(Значение15.Значение.Ссылка, ""null"") КАК ЯзыкИздания,
		               |	ЕСТЬNULL(Значение16.Значение, ""null"") КАК ИмяПереводчика,
		               |	ЕСТЬNULL(Значение17.Значение, ""null"") КАК ИмяИллюстратора,
		               |	ЕСТЬNULL(Значение18.Значение.Ссылка, ""null"") КАК ТипПереплета,
		               |	ЕСТЬNULL(Значение19.Значение, ""null"") КАК is_active,
		               |	ЕСТЬNULL(Значение20.Значение, ""null"") КАК is_available,
		               |	ЕСТЬNULL(Значение21.Значение, ""null"") КАК Издательство,
		               |	НоменклатураСпр.НаименованиеПолное КАК НаименованиеПолное,
		               |	""/5032292394/Images/"" + НоменклатураПрисоединенныеФайлы.ВладелецФайла.Код + НоменклатураПрисоединенныеФайлы.Наименование + ""."" + НоменклатураПрисоединенныеФайлы.Расширение КАК Изображение
		               |ИЗ
		               |	Справочник.Номенклатура КАК НоменклатураСпр
		               |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЦеныНоменклатуры.СрезПоследних(, ВидЦены = &ВидЦены) КАК ЦеныНоменклатурыСрезПоследних
		               |		ПО НоменклатураСпр.Ссылка = ЦеныНоменклатурыСрезПоследних.Номенклатура
		               |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЦеныНоменклатуры.СрезПоследних(, ВидЦены = &ЦенаСоСкидкой) КАК ЦеныНоменклатурыСрезПоследних1
		               |		ПО НоменклатураСпр.Ссылка = ЦеныНоменклатурыСрезПоследних1.Номенклатура
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение1
		               |		ПО (Значение1.Свойство = &Свойство1)
		               |			И НоменклатураСпр.Ссылка = Значение1.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение2
		               |		ПО (Значение2.Свойство = &Свойство2)
		               |			И НоменклатураСпр.Ссылка = Значение2.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение3
		               |		ПО (Значение3.Свойство = &Свойство3)
		               |			И НоменклатураСпр.Ссылка = Значение3.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение4
		               |		ПО (Значение4.Свойство = &Свойство4)
		               |			И НоменклатураСпр.Ссылка = Значение4.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение5
		               |		ПО (Значение5.Свойство = &Свойство5)
		               |			И НоменклатураСпр.Ссылка = Значение5.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение6
		               |		ПО (Значение6.Свойство = &Свойство6)
		               |			И НоменклатураСпр.Ссылка = Значение6.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение7
		               |		ПО (Значение7.Свойство = &Свойство7)
		               |			И НоменклатураСпр.Ссылка = Значение7.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение8
		               |		ПО (Значение8.Свойство = &Свойство8)
		               |			И НоменклатураСпр.Ссылка = Значение8.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение9
		               |		ПО (Значение9.Свойство = &Свойство9)
		               |			И НоменклатураСпр.Ссылка = Значение9.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение10
		               |		ПО (Значение10.Свойство = &Свойство10)
		               |			И НоменклатураСпр.Ссылка = Значение10.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение11
		               |		ПО (Значение11.Свойство = &Свойство11)
		               |			И НоменклатураСпр.Ссылка = Значение11.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение12
		               |		ПО (Значение12.Свойство = &Свойство12)
		               |			И НоменклатураСпр.Ссылка = Значение12.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение13
		               |		ПО (Значение13.Свойство = &Свойство13)
		               |			И НоменклатураСпр.Ссылка = Значение13.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение14
		               |		ПО (Значение14.Свойство = &Свойство14)
		               |			И НоменклатураСпр.Ссылка = Значение14.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение15
		               |		ПО (Значение15.Свойство = &Свойство15)
		               |			И НоменклатураСпр.Ссылка = Значение15.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение16
		               |		ПО (Значение16.Свойство = &Свойство16)
		               |			И НоменклатураСпр.Ссылка = Значение16.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение17
		               |		ПО (Значение17.Свойство = &Свойство17)
		               |			И НоменклатураСпр.Ссылка = Значение17.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение18
		               |		ПО (Значение18.Свойство = &Свойство18)
		               |			И НоменклатураСпр.Ссылка = Значение18.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение19
		               |		ПО (Значение19.Свойство = &Свойство19)
		               |			И НоменклатураСпр.Ссылка = Значение19.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение20
		               |		ПО (Значение20.Свойство = &Свойство20)
		               |			И НоменклатураСпр.Ссылка = Значение20.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Значение21
		               |		ПО (Значение21.Свойство = &Свойство21)
		               |			И НоменклатураСпр.Ссылка = Значение21.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.НоменклатураПрисоединенныеФайлы КАК НоменклатураПрисоединенныеФайлы
		               |		ПО НоменклатураСпр.Ссылка = НоменклатураПрисоединенныеФайлы.ВладелецФайла
		               |ГДЕ
		               |	НоменклатураПрисоединенныеФайлы.Ссылка <> ЗНАЧЕНИЕ(Справочник.НоменклатураПрисоединенныеФайлы.ПустаяСсылка)
		               |	И НЕ Значение1.Значение ПОДОБНО """"
		               |	И НЕ Значение5.Значение ПОДОБНО """"
		               |	И НЕ Значение10.Значение ПОДОБНО """"
		               |	И НоменклатураСпр.Ссылка > &ПоследнийВыгруженныйОбъект
		               |	И (НоменклатураСпр.Ссылка В ИЕРАРХИИ (&Родитель)
		               |			ИЛИ &ВсеРодители)";
		
		Если РазмерПакета > 0 Тогда
			Запрос.Текст = СтрЗаменить(Запрос.Текст,"ВЫБРАТЬ РАЗЛИЧНЫЕ",СТрШаблон("ВЫБРАТЬ РАЗЛИЧНЫЕ ПЕРВЫЕ %1 ",Формат(РазмерПакета,"ЧДЦ=0; ЧГ=0")));
		КонецЕсли;	
		
		Запрос.УстановитьПараметр("ПоследнийВыгруженныйОбъект", ПоследнийВыгруженныйОбъект);
		Запрос.УстановитьПараметр("Родитель", ЭтотОбъект.РодительСув);
		Запрос.УстановитьПараметр("ВсеРодители", Не ЗначениеЗаполнено(ЭтотОбъект.РодительСув));
		Запрос.УстановитьПараметр("ВидЦены", ЭтотОбъект.ВидЦен);
		Запрос.УстановитьПараметр("ЦенаСоСкидкой", ЭтотОбъект.ЦенаСоСкидкой);
		Запрос.УстановитьПараметр("Свойство1", ЭтотОбъект.Свойство1);
		Запрос.УстановитьПараметр("Свойство2", ЭтотОбъект.Свойство2);
		Запрос.УстановитьПараметр("Свойство3", ЭтотОбъект.Свойство3);
		Запрос.УстановитьПараметр("Свойство4", ЭтотОбъект.Свойство4);
		Запрос.УстановитьПараметр("Свойство5", ЭтотОбъект.Свойство5);
		Запрос.УстановитьПараметр("Свойство6", ЭтотОбъект.Свойство6);
		Запрос.УстановитьПараметр("Свойство7", ЭтотОбъект.Свойство7);
		Запрос.УстановитьПараметр("Свойство8", ЭтотОбъект.Свойство8);
		Запрос.УстановитьПараметр("Свойство9", ЭтотОбъект.Свойство9);
		Запрос.УстановитьПараметр("Свойство10", ЭтотОбъект.Свойство10);
		Запрос.УстановитьПараметр("Свойство11", ЭтотОбъект.Свойство11);
		Запрос.УстановитьПараметр("Свойство12", ЭтотОбъект.Свойство12);
		Запрос.УстановитьПараметр("Свойство13", ЭтотОбъект.Свойство13);
		Запрос.УстановитьПараметр("Свойство14", ЭтотОбъект.Свойство14);
		Запрос.УстановитьПараметр("Свойство15", ЭтотОбъект.Свойство15);
		Запрос.УстановитьПараметр("Свойство16", ЭтотОбъект.Свойство16);
		Запрос.УстановитьПараметр("Свойство17", ЭтотОбъект.Свойство17);
		Запрос.УстановитьПараметр("Свойство18", ЭтотОбъект.Свойство18);
		Запрос.УстановитьПараметр("Свойство19", ЭтотОбъект.Свойство19);
		Запрос.УстановитьПараметр("Свойство20", ЭтотОбъект.Свойство20);
		Запрос.УстановитьПараметр("Свойство21", ЭтотОбъект.Свойство21);
		
		
		РезультатЗапроса = Запрос.Выполнить();	  
		
		Если РезультатЗапроса.Пустой() Тогда
			
			// выгружен последний пакет
			ПоследнийВыгруженныйОбъект = Справочники.Номенклатура.ПустаяСсылка();
			ДатаПоследнейВыгрузки = НачалоДня(ТекущаяДатаСеанса());
			
			Результат = СтруктураСообщенияОбОшибке();
			Результат.Успешно = Истина;
			
		Иначе
			
			Выборка = РезультатЗапроса.Выбрать();
			МассивСтрок = Новый Массив;
			
			Пока Выборка.Следующий() Цикл
				
				ПоследнийВыгруженныйОбъект = Выборка.Guid;
				
				Если  ЭтотОбъект.Свойство3 = истина ТОгда 
					Массив = Новый Массив;
					Массив.Добавить(Новый Структура);
				КонецЕсли;
				СтруктураСтроки = ПолучитьСтруктуруСтроки(РезультатЗапроса);
				Если  ЭтотОбъект.Свойство3 = истина ТОгда 
					Массив = Новый Массив;
					Массив.Добавить(ЭтотОбъект.Свойство3);
				КонецЕсли;
				
				ЗаполнитьЗначенияСвойств(СтруктураСтроки, Выборка);
				Если  ЭтотОбъект.Свойство3 = истина ТОгда 
					Массив = Новый Массив;
					Массив.Добавить(ЭтотОбъект.Свойство3);
				КонецЕсли;
				
				СерилизоватьДанные(СтруктураСтроки);
				Если  ЭтотОбъект.Свойство3 = истина ТОгда 
					Массив = Новый Массив;
					Массив.Добавить(ЭтотОбъект.Свойство3);
				КонецЕсли;
				
				МассивСтрок.Добавить(СтруктураСтроки);
				Если  ЭтотОбъект.Свойство3 = истина ТОгда 
					Массив = Новый Массив;
					Массив.Добавить(ЭтотОбъект.Свойство3);
				КонецЕсли;
				
			КонецЦикла; 
			
			Если  ЭтотОбъект.Свойство3 = истина ТОгда 
				Массив = Новый Массив;
				Массив.Добавить(ЭтотОбъект.Свойство3);
			КонецЕсли;
			
			СтруктураВыгрузки = Новый Структура("books", МассивСтрок); 
			КоличествоКВыгрузке = МассивСтрок.Количество();
			
			ЗаписьJSON = Новый ЗаписьJSON();
			ЗаписьJSON.УстановитьСтроку();
			ЗаписьJSON.ПроверятьСтруктуру = Ложь;	
			
			ЗаписатьJSON(ЗаписьJSON, СтруктураВыгрузки);
			СтрокаJSON = ЗаписьJSON.Закрыть();
			
			Результат = ОтправитьДанныеНаСайт(Настройки, СтрокаJSON);
			
			Результат.Вставить("Данные",Новый Структура("ВыгруженоОбъектов",КоличествоКВыгрузке));
			
		КонецЕсли; 
		
		Если Результат.Успешно Тогда
			Настройки.ПоследнийВыгруженныйОбъект = ПоследнийВыгруженныйОбъект;
			Настройки.ДатаПоследнейВыгрузки = ДатаПоследнейВыгрузки;
			СохранитьНастройки(Настройки);
		КонецЕсли; 
		
		
	Исключение
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ТекстСообщения = НСтр("ru = 'Ошибка получения данных для выгрузки на сайт: %1'");
		ТекстСообщения = СтрШаблон(ТекстСообщения,КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		Результат.Успешно = Ложь;
		Результат.ОписаниеОшибки = ТекстСообщения;	
	КонецПопытки;
	
	
	Возврат Результат;
	
КонецФункции

Функция ВыгрузитьСувениры() Экспорт
	
	// получить прараметры соединения
	Результат = ЗагрузитьНастройки();
	Если Не Результат.Успешно Тогда
		Возврат Результат;	
	КонецЕсли; 

	Попытка
		
		Настройки = Результат.Данные;
		Если Настройки.Свойство("ПоследнийВыгруженныйОбъектСувениры") Тогда
			ПоследнийВыгруженныйОбъектСувениры = Настройки.ПоследнийВыгруженныйОбъектСувениры;
		Иначе
			ПоследнийВыгруженныйОбъектСувениры = Справочники.Номенклатура.ПустаяСсылка();
			Настройки.Вставить("ПоследнийВыгруженныйОбъектСувениры",ПоследнийВыгруженныйОбъектСувениры);
		КонецЕсли; 
		
		Если Настройки.Свойство("РазмерПакета") Тогда
			РазмерПакета = Настройки.РазмерПакета;
		Иначе
			РазмерПакета = 0;
			Настройки.Вставить("РазмерПакета",РазмерПакета);			
		КонецЕсли;
		
		Если Настройки.Свойство("ДатаПоследнейВыгрузкиСувениры") Тогда
			ДатаПоследнейВыгрузкиСувениры = Настройки.ДатаПоследнейВыгрузкиСувениры;
		Иначе
			ДатаПоследнейВыгрузкиСувениры = '00010101';
			Настройки.Вставить("ДатаПоследнейВыгрузкиСувениры",ДатаПоследнейВыгрузкиСувениры);						
		КонецЕсли; 
		
		ЗаполнитьЗначенияСвойств(ЭтотОбъект,Настройки);
		
		Если Не ЗначениеЗаполнено(ПоследнийВыгруженныйОбъектСувениры) Тогда
			Если ДатаПоследнейВыгрузкиСувениры >= НачалоДня(ТекущаяДатаСеанса()) Тогда
				// Выгрузка сегодня уже была
				Результат = СтруктураСообщенияОбОшибке();
				Результат.Успешно = Истина;
				Возврат Результат;
			КонецЕсли; 	
		КонецЕсли; 
		
		Запрос = Новый Запрос;
		Запрос.Текст = "ВЫБРАТЬ РАЗЛИЧНЫЕ
		               |	НоменклатураСпр.Ссылка КАК Guid,
		               |	ЕСТЬNULL(Сув_НаименованиеДляСайта.Значение.Наименование, &ПредставлениеNULL) КАК НаименованиеДляСайта,
		               |	НоменклатураСпр.НаименованиеПолное КАК НаименованиеПолное,
		               |	НоменклатураСпр.Артикул КАК Артикул,
		               |	НоменклатураСпр.Производитель КАК Производитель,
		               |	ЕСТЬNULL(ЦеныНоменклатурыСрезПоследних1.Цена, 0) КАК ЦенаСоСкидкой,
		               |	ЕСТЬNULL(ЦеныНоменклатурыСрезПоследних.Цена, 0) КАК Цена,
		               |	НоменклатураСпр.Описание КАК Описание,
		               |	ЕСТЬNULL(Сув_Измерение1.Значение, &ПредставлениеNULL) КАК Измерение1,
		               |	ЕСТЬNULL(Сув_Измерение2.Значение, &ПредставлениеNULL) КАК Измерение2,
		               |	ЕСТЬNULL(Сув_Измерение3.Значение, &ПредставлениеNULL) КАК Измерение3,
		               |	ЕСТЬNULL(Сув_Вес.Значение, &ПредставлениеNULL) КАК Вес,
		               |	ЕСТЬNULL(Сув_СтранаПроизводитель.Значение.Ссылка, &ПредставлениеNULL) КАК СтранаПроизводитель,
		               |	ЕСТЬNULL(Сув_is_active.Значение, &ПредставлениеNULL) КАК is_active,
		               |	ЕСТЬNULL(Сув_is_available.Значение, &ПредставлениеNULL) КАК is_available,
		               |	ЕСТЬNULL(Сув_Материал.Значение.Наименование, &ПредставлениеNULL) КАК Материал,
		               |	ЕСТЬNULL(Сув_Цвет.Значение.Ссылка, &ПредставлениеNULL) КАК Цвет,
		               |	ЕСТЬNULL(Сув_ТорговаяМарка.Значение, &ПредставлениеNULL) КАК ТорговаяМарка,
		               |	ЕСТЬNULL(Сув_Объем.Значение, &ПредставлениеNULL) КАК Объем,
		               |	ЕСТЬNULL(Сув_ISBN.Значение, &ПредставлениеNULL) КАК ISBN,
		               |	""/5032292394/Images/"" + НоменклатураПрисоединенныеФайлы.ВладелецФайла.Код + НоменклатураПрисоединенныеФайлы.Наименование + ""."" + НоменклатураПрисоединенныеФайлы.Расширение КАК Изображение
		               |ИЗ
		               |	Справочник.Номенклатура КАК НоменклатураСпр
		               |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЦеныНоменклатуры.СрезПоследних(, ВидЦены = &ВидЦены) КАК ЦеныНоменклатурыСрезПоследних
		               |		ПО НоменклатураСпр.Ссылка = ЦеныНоменклатурыСрезПоследних.Номенклатура
		               |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЦеныНоменклатуры.СрезПоследних(, ВидЦены = &ЦенаСоСкидкой) КАК ЦеныНоменклатурыСрезПоследних1
		               |		ПО НоменклатураСпр.Ссылка = ЦеныНоменклатурыСрезПоследних1.Номенклатура
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Материал
		               |		ПО (Сув_Материал.Свойство = &Сув_Материал)
		               |			И НоменклатураСпр.Ссылка = Сув_Материал.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Цвет
		               |		ПО (Сув_Цвет.Свойство = &Сув_Цвет)
		               |			И НоменклатураСпр.Ссылка = Сув_Цвет.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_ТорговаяМарка
		               |		ПО (Сув_ТорговаяМарка.Свойство = &Сув_ТорговаяМарка)
		               |			И НоменклатураСпр.Ссылка = Сув_ТорговаяМарка.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_НаименованиеДляСайта
		               |		ПО (Сув_НаименованиеДляСайта.Свойство = &Сув_НаименованиеДляСайта)
		               |			И НоменклатураСпр.Ссылка = Сув_НаименованиеДляСайта.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Объем
		               |		ПО (Сув_Объем.Свойство = &Сув_Объем)
		               |			И НоменклатураСпр.Ссылка = Сув_Объем.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Измерение1
		               |		ПО (Сув_Измерение1.Свойство = &Сув_Измерение1)
		               |			И НоменклатураСпр.Ссылка = Сув_Измерение1.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Измерение2
		               |		ПО (Сув_Измерение2.Свойство = &Сув_Измерение2)
		               |			И НоменклатураСпр.Ссылка = Сув_Измерение2.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Измерение3
		               |		ПО (Сув_Измерение3.Свойство = &Сув_Измерение3)
		               |			И НоменклатураСпр.Ссылка = Сув_Измерение3.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_Вес
		               |		ПО (Сув_Вес.Свойство = &Сув_Вес)
		               |			И НоменклатураСпр.Ссылка = Сув_Вес.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_СтранаПроизводитель
		               |		ПО (Сув_СтранаПроизводитель.Свойство = &Сув_СтранаПроизводитель)
		               |			И НоменклатураСпр.Ссылка = Сув_СтранаПроизводитель.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_is_active
		               |		ПО (Сув_is_active.Свойство = &Сув_is_active)
		               |			И НоменклатураСпр.Ссылка = Сув_is_active.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_is_available
		               |		ПО (Сув_is_available.Свойство = &Сув_is_available)
		               |			И НоменклатураСпр.Ссылка = Сув_is_available.Ссылка
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Номенклатура.ДополнительныеРеквизиты КАК Сув_ISBN
		               |		ПО (Сув_ISBN.Свойство = &Сув_ISBN)
		               |			И НоменклатураСпр.Ссылка = Сув_ISBN.Ссылка					   
		               |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.НоменклатураПрисоединенныеФайлы КАК НоменклатураПрисоединенныеФайлы
		               |		ПО НоменклатураСпр.Ссылка = НоменклатураПрисоединенныеФайлы.ВладелецФайла
		               |ГДЕ
		               |	НоменклатураПрисоединенныеФайлы.Ссылка <> ЗНАЧЕНИЕ(Справочник.НоменклатураПрисоединенныеФайлы.ПустаяСсылка)
		               |	И НоменклатураСпр.НаименованиеПолное <> """"
		               |	И ЕСТЬNULL(ЦеныНоменклатурыСрезПоследних1.Цена, 0) <> 0
		               |	И Сув_Вес.Значение <> """"
		               |	И НоменклатураСпр.Ссылка > &ПоследнийВыгруженныйОбъект
		               |	И (НоменклатураСпр.Ссылка В ИЕРАРХИИ (&Родитель)
		               |			ИЛИ &ВсеРодители)";
		
		Если РазмерПакета > 0 Тогда
			Запрос.Текст = СтрЗаменить(Запрос.Текст,"ВЫБРАТЬ РАЗЛИЧНЫЕ",СТрШаблон("ВЫБРАТЬ РАЗЛИЧНЫЕ ПЕРВЫЕ %1 ",Формат(РазмерПакета,"ЧДЦ=0; ЧГ=0")));
		КонецЕсли;	
		
		Запрос.УстановитьПараметр("ПредставлениеNULL","null");
		Запрос.УстановитьПараметр("ПоследнийВыгруженныйОбъект", ПоследнийВыгруженныйОбъектСувениры);
		Запрос.УстановитьПараметр("Родитель", ЭтотОбъект.РодительСув);
		Запрос.УстановитьПараметр("ВсеРодители", Не ЗначениеЗаполнено(ЭтотОбъект.РодительСув));
		Запрос.УстановитьПараметр("ВидЦены", ЭтотОбъект.ВидЦенСувениры);
		Запрос.УстановитьПараметр("ЦенаСоСкидкой", ЭтотОбъект.ЦенаСоСкидкойСувениры);
		Запрос.УстановитьПараметр("Сув_Материал", ЭтотОбъект.Сув_Материал);
		Запрос.УстановитьПараметр("Сув_Цвет", ЭтотОбъект.Сув_Цвет);
		Запрос.УстановитьПараметр("Сув_ТорговаяМарка", ЭтотОбъект.Сув_ТорговаяМарка);
		Запрос.УстановитьПараметр("Сув_НаименованиеДляСайта", ЭтотОбъект.Сув_НаименованиеДляСайта);
		Запрос.УстановитьПараметр("Сув_Объем", ЭтотОбъект.Сув_Объем);
		Запрос.УстановитьПараметр("Сув_Измерение1", ЭтотОбъект.Сув_Измерение1);
		Запрос.УстановитьПараметр("Сув_Измерение2", ЭтотОбъект.Сув_Измерение2);
		Запрос.УстановитьПараметр("Сув_Измерение3", ЭтотОбъект.Сув_Измерение3);
		Запрос.УстановитьПараметр("Сув_Вес", ЭтотОбъект.Сув_Вес);
		Запрос.УстановитьПараметр("Сув_СтранаПроизводитель", ЭтотОбъект.Сув_СтранаПроизводитель);
		Запрос.УстановитьПараметр("Сув_is_active", ЭтотОбъект.Сув_is_active);
		Запрос.УстановитьПараметр("Сув_is_available", ЭтотОбъект.Сув_is_available);
		Запрос.УстановитьПараметр("Сув_ISBN", ЭтотОбъект.Сув_ISBN);
				
		
		РезультатЗапроса = Запрос.Выполнить();	  
		
		Если РезультатЗапроса.Пустой() Тогда
			
			// выгружен последний пакет
			ПоследнийВыгруженныйОбъектСувениры = Справочники.Номенклатура.ПустаяСсылка();
			ДатаПоследнейВыгрузкиСувениры = НачалоДня(ТекущаяДатаСеанса());
			
			Результат = СтруктураСообщенияОбОшибке();
			Результат.Успешно = Истина;
			
		Иначе
			
			Выборка = РезультатЗапроса.Выбрать();
			МассивПозиций = Новый Массив;
			
			Пока Выборка.Следующий() Цикл
				
				ПоследнийВыгруженныйОбъектСувениры = Выборка.Guid;
				
				ДанныеПозиции = ОбщегоНазначения.СтрокаТаблицыЗначенийВСтруктуру(Выборка);
				СерилизоватьДанные(ДанныеПозиции);
				МассивПозиций.Добавить(ДанныеПозиции);
				
			КонецЦикла; 
						
			СтруктураВыгрузки = Новый Структура("souvenirs", МассивПозиций); 
			КоличествоКВыгрузке = МассивПозиций.Количество();
			
			ЗаписьJSON = Новый ЗаписьJSON();
			ЗаписьJSON.УстановитьСтроку();
			ЗаписьJSON.ПроверятьСтруктуру = Ложь;	
			
			ЗаписатьJSON(ЗаписьJSON, СтруктураВыгрузки);
			СтрокаJSON = ЗаписьJSON.Закрыть();
			
			Результат = ОтправитьДанныеНаСайт(Настройки, СтрокаJSON);
			
			Результат.Вставить("Данные",Новый Структура("ВыгруженоОбъектов",КоличествоКВыгрузке));
			
		КонецЕсли; 
		
		Если Результат.Успешно Тогда
			Настройки.ПоследнийВыгруженныйОбъектСувениры = ПоследнийВыгруженныйОбъектСувениры;
			Настройки.ДатаПоследнейВыгрузкиСувениры = ДатаПоследнейВыгрузкиСувениры;
			СохранитьНастройки(Настройки);
		КонецЕсли; 
		
		
	Исключение
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ТекстСообщения = НСтр("ru = 'Ошибка получения данных для выгрузки на сайт: %1'");
		ТекстСообщения = СтрШаблон(ТекстСообщения,КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		Результат.Успешно = Ложь;
		Результат.ОписаниеОшибки = ТекстСообщения;	
		Результат.Удалить("Данные");
	КонецПопытки;
	
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьСтруктуруСтроки(РезультатЗапроса)
	
	Структура = Новый Структура;
	Для Каждого Кол Из РезультатЗапроса.Колонки Цикл
		Структура.Вставить(Кол.Имя);	
	КонецЦикла;	
	Возврат Структура;
	
КонецФункции

Процедура СерилизоватьДанные(Структура)
	
	Для Каждого Эл Из Структура Цикл
		
		Значение = Эл.Значение;
		
		Если ТипЗнч(Значение) = Тип("Строка") Тогда
			//	
		ИначеЕсли ТипЗнч(Значение) = Тип("Число") Тогда
			//
		ИначеЕсли ТипЗнч(Значение) = Тип("Булево") Тогда
			//
		//ИначеЕсли ТипЗнч(Значение) = Тип("null") Тогда
		//	
		Иначе
			
			Структура[Эл.Ключ] = XMLСтрока(Значение);
			
		КонецЕсли; 
		
	КонецЦикла; 

КонецПроцедуры

Функция СтруктураСообщенияОбОшибке()
	Возврат Новый Структура("Успешно,ОписаниеОшибки",Ложь,"");	
КонецФункции //ПолучитьСтрукутруСообщенияОбОшибке

Функция КлючНастроек()

	Возврат "НастройкиВыгрузкиДанныхНаСайт_dostoevsky_club";

КонецФункции // КлючНастроек()
 
Функция ЗагрузитьНастройки() Экспорт

	Попытка
		Результат = СтруктураСообщенияОбОшибке();
		КлючНастроек = КлючНастроек();
		Данные = ОбщегоНазначения.ПрочитатьДанныеИзБезопасногоХранилища(КлючНастроек,КлючНастроек); 		
		Результат.Успешно = Истина;
		Результат.Вставить("Данные",Данные);
	Исключение
	    ИнформацияОбОшибке = ИнформацияОбОшибке();
		ТекстСообщения = НСтр("ru = 'Ошибка загрузки параметров: %1'");
		ТекстСообщения = СтрШаблон(ТекстСообщения,КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		Результат.Успешно = Ложь;
		Результат.ОписаниеОшибки = ТекстСообщения;	
	КонецПопытки;
	
	Возврат Результат;
	
КонецФункции // ЗагрузитьНастройки()
 
Функция СохранитьНастройки(СтруктураНастроек) Экспорт

	Попытка
		Результат = СтруктураСообщенияОбОшибке();
		КлючНастроек = КлючНастроек();
		ОбщегоНазначения.ЗаписатьДанныеВБезопасноеХранилище(КлючНастроек, СтруктураНастроек, КлючНастроек); 		
		Результат.Успешно = Истина;
	Исключение
	    ИнформацияОбОшибке = ИнформацияОбОшибке();
		ТекстСообщения = НСтр("ru = 'Ошибка сохранения параметров выгрузки на сайт: %1'");
		ТекстСообщения = СтрШаблон(ТекстСообщения,КраткоеПредставлениеОшибки(ИнформацияОбОшибке));
		Результат.Успешно = Ложь;
		Результат.ОписаниеОшибки = ТекстСообщения;	
	КонецПопытки;
	
	Возврат Результат;

КонецФункции // СохранитьНастройки()


////////////////////////////////////////////////////////////

Функция СведенияОВнешнейОбработке() Экспорт
	
	ПараметрыРегистрации = ДополнительныеОтчетыИОбработки.СведенияОВнешнейОбработке("2.4.5.71");
	ПараметрыРегистрации.Вставить("БезопасныйРежим", Ложь);
	
	ПараметрыРегистрации.Вид = ДополнительныеОтчетыИОбработкиКлиентСервер.ВидОбработкиДополнительнаяОбработка();
	ПараметрыРегистрации.Версия = "2.1";
	
	ПараметрыРегистрации.Информация = "Выгрузка номенклатуры на сайт dostoevsky-club.ru";
	
	//Открываем форму
	НоваяКоманда = ПараметрыРегистрации.Команды.Добавить();
	НоваяКоманда.Представление = НСтр("ru = 'Интерактивный запуск и установка настроек'");
	НоваяКоманда.Идентификатор = "НастроитьИВыполнитьВыгрузкуВручную";
	НоваяКоманда.Использование = ДополнительныеОтчетыИОбработкиКлиентСервер.ТипКомандыОткрытиеФормы();
	НоваяКоманда.ПоказыватьОповещение = Ложь;
	
	//Регламент книги
	НоваяКоманда = ПараметрыРегистрации.Команды.Добавить();
	НоваяКоманда.Представление = НСтр("ru = 'Запуск выгрузки книг по регламенту'");
	НоваяКоманда.Идентификатор = "ВыгрузкаКнигРегламент";
	НоваяКоманда.Использование = ДополнительныеОтчетыИОбработкиКлиентСервер.ТипКомандыВызовСерверногоМетода();
	НоваяКоманда.ПоказыватьОповещение = Истина;
	
	//Регламент сувениры
	НоваяКоманда = ПараметрыРегистрации.Команды.Добавить();
	НоваяКоманда.Представление = НСтр("ru = 'Запуск выгрузки сувениров по регламенту'");
	НоваяКоманда.Идентификатор = "ВыгрузкаСувенировРегламент";
	НоваяКоманда.Использование = ДополнительныеОтчетыИОбработкиКлиентСервер.ТипКомандыВызовСерверногоМетода();
	НоваяКоманда.ПоказыватьОповещение = Истина;

	Возврат ПараметрыРегистрации;	
	
КонецФункции

// Интерфейс для запуска логики обработки.
Процедура ВыполнитьКоманду(ИмяКоманды, ПараметрыВыполнения) Экспорт
	
	// Диспетчеризация обработчиков команд.
	Если ИмяКоманды = "ВыгрузкаКнигРегламент" Тогда
		Результат = Выгрузить();
		ТекстСообщения = "";
		Если Результат.Успешно Тогда
			Если Результат.Свойство("Данные") Тогда
				// если была выгрузка, сообщаем количество
				УровеньЖурнала = УровеньЖурналаРегистрации.Информация;
				ТекстСообщения = СтрШаблон("Успешно выгружены на сайт данные о номенклатуре. Выгружено позиций: %1",Результат.Данные.ВыгруженоОбъектов);		
			КонецЕсли; 
		Иначе		
			УровеньЖурнала = УровеньЖурналаРегистрации.Ошибка;
			ТекстСообщения = СтрШаблон("Ошибка выгрузки на сайт данных о номенклатуре: %1",Результат.ОписаниеОшибки);			
		КонецЕсли;
		Если Не ПустаяСтрока(ТекстСообщения) Тогда
			ЗаписьЖурналаРегистрации("Выгрузка номенклатуры на сайт",УровеньЖурнала,,,ТекстСообщения);		
		КонецЕсли; 
	ИначеЕсли ИмяКоманды = "ВыгрузкаСувенировРегламент" Тогда 	
		Результат = ВыгрузитьСувениры();
		ТекстСообщения = "";
		Если Результат.Успешно Тогда
			Если Результат.Свойство("Данные") Тогда
				// если была выгрузка, сообщаем количество
				УровеньЖурнала = УровеньЖурналаРегистрации.Информация;
				ТекстСообщения = СтрШаблон("Успешно выгружены на сайт данные о сувенирной продукции. Выгружено позиций: %1",Результат.Данные.ВыгруженоОбъектов);		
			КонецЕсли; 
		Иначе		
			УровеньЖурнала = УровеньЖурналаРегистрации.Ошибка;
			ТекстСообщения = СтрШаблон("Ошибка выгрузки на сайт данных о сувенирной продукции: %1",Результат.ОписаниеОшибки);			
		КонецЕсли;
		Если Не ПустаяСтрока(ТекстСообщения) Тогда
			ЗаписьЖурналаРегистрации("Выгрузка сувенирной продукции на сайт",УровеньЖурнала,,,ТекстСообщения);		
		КонецЕсли; 		
	КонецЕсли;
	
КонецПроцедуры