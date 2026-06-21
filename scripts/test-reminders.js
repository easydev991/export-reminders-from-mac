#!/usr/bin/osascript -l JavaScript

console.log("1. Запуск скрипта...");

const Reminders = Application('Reminders');
console.log("2. Application получено");

console.log("3. Получаю списки...");
const lists = Reminders.lists();
console.log("4. Списки получены, количество: " + lists.length);

if (lists.length > 0) {
  lists.forEach((list, i) => {
    console.log((i + 1) + ". Список: " + list.name());
    const reminders = list.reminders();
    console.log("   В нём напоминаний: " + reminders.length);
  });
}

console.log("5. Завершено");
