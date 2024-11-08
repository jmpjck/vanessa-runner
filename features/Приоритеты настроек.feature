# language: ru

Функционал: Приоритеты настроек
    Как разработчик
    Я хочу иметь возможность использовать различные настройки команды с правильным приоритетом
    Чтобы выполнять коллективную разработку проекта 1С с помощью удобных шаблонов
    приоритет настроек, от максимального до минимального:
    - командная строка
    - переменные окружения
    - json-файл настроек, заданный в --settings
    - env.json - файл настроек в корне проекта, если явно не указаны настройки через --settings
    внутри json-файлов следующие приоритеты, от максимального до минимального:
    - настройки секции по имени команды
    - настройки секции по имени "--default"

Контекст:
    Дано Я сохраняю значение "" в переменную окружения "RUNNER_SRC"
    И Я очищаю параметры команды "oscript" в контексте

Сценарий: Подготовка ИБ
    # Допустим  я включаю отладку лога с именем "oscript.app.vanessa-runner"
    # Допустим  я включаю отладку лога с именем "oscript.lib.v8runner"
    # И Я сохраняю значение "DEBUG" в переменную окружения "LOGOS_LEVEL"
    # Допустим  я включаю отладку лога с именем "bdd"

    # Допустим Я создаю временный каталог и сохраняю его в контекст
    # И Я устанавливаю временный каталог как рабочий каталог

    # Допустим Я создаю каталог "build/out" в рабочем каталоге
    # И Я копирую каталог "cf" из каталога "tests/fixtures" проекта в рабочий каталог

    # И Я установил рабочий каталог как текущий каталог
    # Когда Я сохраняю каталог проекта в контекст

    Допустим я подготовил репозиторий и рабочий каталог проекта
    И Я копирую каталог "cf" из каталога "tests/fixtures" проекта в рабочий каталог
    # И я подготовил рабочую базу проекта "./build/ib" по умолчанию

    # И Я сохраняю значение "INFO" в переменную окружения "LOGOS_LEVEL"
    # Дано Я очищаю параметры команды "oscript" в контексте

    # Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os init-dev --src ./cf --nocacheuse --language ru"
    # Тогда Вывод команды "oscript" содержит "Обновление конфигурации базы данных успешно завершено"
    # # Тогда Вывод команды "oscript" содержит "Database configuration successfully updated"
    # # Тогда Я показываю вывод команды

    # И Код возврата команды "oscript" равен 0

    И Я очищаю параметры команды "oscript" в контексте

Сценарий: Полная проверка
    Когда Я сохраняю значение "ПутьИзПеременныхОкружения" в переменную окружения "RUNNER_SRC"

    Когда Я создаю файл "add.json" с текстом
        """
        {
        "--default": {
            "--new-version":"ВерсияИзФайла-Умолчание-Settings",
            "--src":"ПутьИзФайла-Умолчание-Settings"
        },
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда-Settings",
            "--src":"ПутьИзФайла-Команда-Settings"
        }
        }
        """
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "--default": {
            "--new-version":"ПользовательИзФайла-Умолчание",
            "--src":"ПутьИзФайла-Умолчание"
        },
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version --new-version ВерсияИзКоманднойСтроки --src ПутьИзКоманднойСтроки --language ru"
    
    # Тогда Я показываю вывод команды

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзКоманднойСтроки |

Сценарий: Настройки из переменных окружения приоритетнее файла настроек из --settings
    И Я сохраняю значение "ПутьИзПеременныхОкружения" в переменную окружения "RUNNER_SRC"
    Когда Я создаю файл "add.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда-Settings",
            "--src":"ПутьИзФайла-Команда-Settings"
        }
        }
        """
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version --settings add.json --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзПеременныхОкружения |

Сценарий: Настройки из переменных окружения приоритетнее файла настроек по умолчанию
    И Я сохраняю значение "ПутьИзПеременныхОкружения" в переменную окружения "RUNNER_SRC"
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзПеременныхОкружения |

Сценарий: Настройки в json-файле по ключу --settings приоритетнее файла настроек по умолчанию
    Когда Я создаю файл "add.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда-Settings",
            "--src":"ПутьИзФайла-Команда-Settings"
        }
        }
        """
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version  --settings add.json --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзФайла-Команда-Settings |

Сценарий: Если задан ключ --settings, то файл настроек по умолчанию (env.json) не используется
    Когда Я создаю файл "add.json" с текстом
        """
        {
        "set-version": {
            "--src":"ПутьИзФайла-Команда-Settings"
        }
        }
        """
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version  --settings add.json --language ru"
    И Я показываю вывод команды
    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на  - ПутьИзФайла-Команда-Settings |

Сценарий: Настройки команды в файле настроек по ключу --settings приоритетнее настроек по умолчанию из ключа "--default"
    
    Дано Я пропускаю этот сценарий в Windows

    Когда Я создаю файл "add.json" с текстом
        """
        {
        "--default": {
            "--new-version":"ВерсияИзФайла-Умолчание-Settings",
            "--src":"ПутьИзФайла-Умолчание-Settings"
        },
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда-Settings"
        }
        }
        """
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version  --settings add.json --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзФайла-Умолчание-Settings |

Сценарий: Настройки из файла по умолчанию (env.json) дополняют нехватающие настройки
    Когда Я создаю файл "env.json" с текстом
        """
        {
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда",
            "--src":"ПутьИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзФайла-Команда |

Сценарий: Настройки команды из файла по умолчанию (env.json) приоритетнее настроек по умолчанию из ключа "--default" в этом файле
    
    Дано Я пропускаю этот сценарий в Windows

    Когда Я создаю файл "env.json" с текстом
        """
        {
        "--default": {
            "--new-version":"ПользовательИзФайла-Умолчание",
            "--src":"ПутьИзФайла-Умолчание"
        },
        "set-version": {
            "--new-version":"ВерсияИзФайла-Команда"
        }
        }
        """

    Когда Я выполняю команду "oscript" с параметрами "<КаталогПроекта>/src/main.os set-version --new-version ВерсияИзКоманднойСтроки --language ru"

    Тогда Вывод команды "oscript" содержит
        | Изменяю версию в исходниках конфигурации 1С на ВерсияИзКоманднойСтроки - ПутьИзФайла-Умолчание |
