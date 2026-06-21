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

// Вывод в stdout — для перенаправления в файл: osascript -l JavaScript export-reminders.js > reminders_export.json
console.log(JSON.stringify(allItems, null, 2));
