-- export-reminders.applescript
-- Запуск: osascript export-reminders.applescript

use scripting additions
use framework "Foundation"

set projectDir to "/Users/Oleg991/Documents/GitHub/export-reminders"
set filePath to projectDir & "/reminders_export.json"
set startTime to current date

log "Начинаю сбор напоминаний..."

tell application "Reminders"
	set allLists to every list
	set listCount to (count of allLists)
	log "Найдено списков: " & listCount
	
	-- Формируем JSON-массив
	set jsonOutput to "[" & return
	
	set totalProcessed to 0
	set listIdx to 0
	
	repeat with myList in allLists
		set listIdx to listIdx + 1
		set listName to name of myList
		set reminderList to every reminder of myList
		set reminderCount to (count of reminderList)
		
		log (listIdx as text) & "/" & (listCount as text) & " Список: \"" & listName & "\" (" & reminderCount & " напоминаний)"
		
		set rIdx to 0
		repeat with r in reminderList
			set rIdx to rIdx + 1
			set totalProcessed to totalProcessed + 1
			
			-- Получаем все свойства одной пачкой (batch внутри tell)
			try
				set rName to name of r
				if rName is missing value then set rName to ""
			on error
				set rName to ""
			end try
			
			try
				set rBody to body of r
				if rBody is missing value then set rBody to ""
			on error
				set rBody to ""
			end try
			
			try
				set rDueDate to due date of r
				if rDueDate is missing value then set rDueDate to missing value
			on error
				set rDueDate to missing value
			end try
			
			try
				set rCompleted to completed of r
				if rCompleted is missing value then set rCompleted to false
			on error
				set rCompleted to false
			end try
			
			try
				set rPriority to priority of r
				if rPriority is missing value then set rPriority to 0
			on error
				set rPriority to 0
			end try
			
			try
				set rCompletedDate to completion date of r
				if rCompletedDate is missing value then set rCompletedDate to missing value
			on error
				set rCompletedDate to missing value
			end try
			
			try
				set rCreationDate to creation date of r
				if rCreationDate is missing value then set rCreationDate to missing value
			on error
				set rCreationDate to missing value
			end try
			
			try
				set rModDate to modification date of r
				if rModDate is missing value then set rModDate to missing value
			on error
				set rModDate to missing value
			end try
			
			-- Форматируем дату в строку
			set dueDateStr to "null"
			if rDueDate is not missing value then
				set dueDateStr to my dateToISO(rDueDate)
			end if
			
			set completedDateStr to "null"
			if rCompletedDate is not missing value then
				set completedDateStr to my dateToISO(rCompletedDate)
			end if
			
			set creationDateStr to "null"
			if rCreationDate is not missing value then
				set creationDateStr to my dateToISO(rCreationDate)
			end if
			
			set modDateStr to "null"
			if rModDate is not missing value then
				set modDateStr to my dateToISO(rModDate)
			end if
			
			-- Экранируем строки для JSON
			set escapedName to my escapeJSON(rName)
			set escapedBody to my escapeJSON(rBody)
			set escapedList to my escapeJSON(listName)
			
			-- Добавляем разделитель
			if totalProcessed > 1 then
				set jsonOutput to jsonOutput & "," & return
			end if
			
			-- Формируем JSON-объект для напоминания
			set jsonOutput to jsonOutput & "{" & return
			set jsonOutput to jsonOutput & "  \"list\": " & escapedList & "," & return
			set jsonOutput to jsonOutput & "  \"title\": " & escapedName & "," & return
			set jsonOutput to jsonOutput & "  \"notes\": " & escapedBody & "," & return
			set jsonOutput to jsonOutput & "  \"dueDate\": " & dueDateStr & "," & return
			set jsonOutput to jsonOutput & "  \"completed\": " & rCompleted & "," & return
			set jsonOutput to jsonOutput & "  \"priority\": " & rPriority & "," & return
			set jsonOutput to jsonOutput & "  \"completionDate\": " & completedDateStr & "," & return
			set jsonOutput to jsonOutput & "  \"creationDate\": " & creationDateStr & "," & return
			set jsonOutput to jsonOutput & "  \"modificationDate\": " & modDateStr & return
			set jsonOutput to jsonOutput & "}"
			
			-- Лог каждые 100 напоминаний
			if totalProcessed mod 100 = 0 then
				log "  ...обработано " & totalProcessed & " напоминаний"
			end if
		end repeat
		
		log "  ✓ список \"" & listName & "\" готов"
	end repeat
end tell

-- Закрываем JSON-массив
set jsonOutput to jsonOutput & return & "]"

log "Всего обработано: " & totalProcessed & " напоминаний"
log "Запись файла..."

-- Записываем в файл
try
	set fileDescriptor to open for access filePath with write permission
	set eof fileDescriptor to 0
	write jsonOutput to fileDescriptor as text
	close access fileDescriptor
	log "✓ Файл сохранён: " & filePath
on error errMsg
	log "✗ Ошибка записи: " & errMsg
	try
		close access filePath
	end try
end try

set endTime to current date
set elapsed to (endTime - startTime) as text
log "Готово! Затрачено времени: " & elapsed & " секунд"

-- Вспомогательные обработчики

on escapeJSON(str)
	if str is "" then return "null"
	set theString to str as text
	
	-- Экранируем обратную косую черту
	set AppleScript's text item delimiters to "\\"
	set theString to text items of theString
	set AppleScript's text item delimiters to "\\\\"
	set theString to theString as text
	
	-- Экранируем кавычки
	set AppleScript's text item delimiters to "\""
	set theString to text items of theString
	set AppleScript's text item delimiters to "\\\""
	set theString to theString as text
	
	-- Экранируем управляющие символы
	set AppleScript's text item delimiters to return
	set theString to text items of theString
	set AppleScript's text item delimiters to "\\n"
	set theString to theString as text
	
	set AppleScript's text item delimiters to tab
	set theString to text items of theString
	set AppleScript's text item delimiters to "\\t"
	set theString to theString as text
	
	set AppleScript's text item delimiters to ""
	
	return "\"" & theString & "\""
end escapeJSON

on dateToISO(d)
	set {year:y, month:m, day:d, hours:h, minutes:min, seconds:s} to d
	set yStr to y as text
	set mStr to text -1 thru -2 of ("0" & ((m as integer) as text))
	set dStr to text -1 thru -2 of ("0" & (d as text))
	set hStr to text -1 thru -2 of ("0" & (h as text))
	set minStr to text -1 thru -2 of ("0" & (min as text))
	set sStr to text -1 thru -2 of ("0" & (s as text))
	return "\"" & yStr & "-" & mStr & "-" & dStr & "T" & hStr & ":" & minStr & ":" & sStr & "\""
end dateToISO
