# Мониторинг Self-Hosted Runner через Zabbix

Скрипт проверяет состояние self-hosted раннера GitHub Actions и отправляет результаты в Zabbix
Он определяет, запущен ли процесс Runner.Listener, получает статус раннера через GitHub API и вычисляет, не является ли раннер «зомби»

## Что делает скрипт?

1. Проверяет наличие процесса Runner.Listener
2. Если процесс запущен — обращается к GitHub API:
   - для репозитория: https://api.github.com/repos/{owner}/{repo}/actions/runners
   - для организации: https://api.github.com/orgs/{owner}/actions/runners
3. Находит раннер с именем RUNNER_NAME и получает его status и last_contact
4. Если раннер не online или время последнего контакта превышает MAX_LAST_CONTACT_MINUTES минут — считает его проблемным
5. Отправляет в Zabbix два значения:
   - runner.status — 1 (ОК) или 0 (проблема)
   - runner.reason — текстовое описание причины

## Зачем нужен GitHub Token?

GitHub API требует аутентификацию для доступа к списку раннеров. Без токена запрос вернёт ошибку 401/403
Токен должен иметь право на чтение информации о self-hosted раннерах

### Как создать токен:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Выберите Fine-grained tokens
3. Дайте доступ к нужному репозиторию или организации
4. В разделе Repository permissions или Organization permissions выберите Self-hosted runners → Read-only
5. Создайте токен и сохраните его

## Переменные окружения

| Переменная               | Обязательная | Описание                                                                 |
|--------------------------|--------------|--------------------------------------------------------------------------|
| GITHUB_TOKEN            | да           | Токен GitHub для API                                                      |
| REPO_OWNER              | да           | Владелец репозитория или организация                                      |
| REPO_NAME               | нет          | Имя репозитория. Если пусто — мониторятся раннеры организации             |
| RUNNER_NAME             | нет          | Имя раннера. По умолчанию hostname                                        |
| ZABBIX_SERVER           | да           | IP или DNS имя Zabbix сервера                                            |
| ZABBIX_HOST             | нет          | Имя хоста в Zabbix. По умолчанию hostname                                |
| MAX_LAST_CONTACT_MINUTES | нет        | Порог «зомби» в минутах. По умолчанию 10                                 |
