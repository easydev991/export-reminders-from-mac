#!/usr/bin/osascript -l JavaScript

// export-reminders.js — запуск: osascript -l JavaScript export-reminders.js
const Reminders = Application('Reminders');
const lists = Reminders.lists();
const allItems = [];
let totalProcessed = 0;

lists.forEach((list, listIndex) => {
  const listName = list.name();
  const reminders = list.reminders();

  console.log((listIndex + 1) + "/" + lists.length + " Список: \"" + listName + "\" (" + reminders.length + " напоминаний)");

  reminders.forEach((r, rIndex) => {
    let recurrenceRule = "";
    try {
      recurrenceRule = r.recurrence() || "";
    } catch(e) {
      recurrenceRule = "";
    }

    allItems.push({
      list: listName,
      title: r.name() || "",
      notes: r.body() || "",
      dueDate: r.dueDate() ? r.dueDate().toString() : null,
      completed: r.completed() || false,
      priority: r.priority() || 0,
      recurrence: recurrenceRule
    });

    totalProcessed++;

    if (totalProcessed % 100 === 0) {
      console.log("  ...обработано " + totalProcessed + " напоминаний");
    }
  });

  console.log("  ✓ список готов (" + reminders.length + " напоминаний)");
});

console.log("Всего обработано: " + totalProcessed + " напоминаний");

// Запись в папку проекта
const app = Application.currentApplication();
app.includeStandardAdditions = true;

const filePath = "./reminders_export.json";

console.log("Запись файла: " + filePath);
const file = app.openForAccess(Path(filePath), { writePermission: true });
app.setEof(file, { to: 0 });
app.write(JSON.stringify(allItems, null, 2), { to: file, as: "text" });
app.closeAccess(file);

console.log("Успешно экспортировано! Файл: " + filePath);
