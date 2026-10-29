# Лабораторная работа 2. Конкурентный контейнер

Реализация контейнеризированного сервиса для конкурентной синхронизации и управления файлами на общем томе Docker без состояний гонки (race condition).

## Описание работы

Сервис запускается внутри Docker-контейнера и в бесконечном цикле выполняет поочерёдное создание и удаление файлов в общем каталоге с задержкой в 1 секунду между операциями:

1. **Атомарность и исключение гонок**: поиск первого свободного трёхзначного имени (`001`, `002`, `003`...) и создание файла выполняются внутри критической секции с использованием утилиты `flock` на служебном файле `.lock`. Это гарантирует отсутствие коллизий даже при высокой конкуренции.
2. **Идентификация и счётчик**: контейнер генерирует фиксированный UUID при старте и записывает его во все свои файлы вместе с инкрементируемым номером итерации.
3. **Безопасное завершение**: в скрипте настроен перехват сигналов завершения (`SIGTERM`, `SIGINT`, `SIGHUP`) через `trap` для корректного удаления временного файла из тома при остановке контейнера.
4. **Легковесность**: образ собран на базе Alpine Linux, а логика реализована на переносимом POSIX Shell.

## Структура проекта

* `worker.sh` — POSIX Shell скрипт логики конкурентного создания и удаления файлов с файловой блокировкой.
* `Dockerfile` — инструкции сборки образа контейнера.
* `README.md` — описание проекта и инструкции по запуску.

## Сборка и запуск

### 1. Подготовка окружения

Сборка образа и создание разделяемого тома:

```sh
docker build -t concurrent-worker:1.0 .
docker volume create shared-data

Запуск в 1 экземпляре

docker run -d --name worker_1 -v shared-data:/shared concurrent-worker:1.0

Проверка содержимого:

docker run --rm -v shared-data:/shared alpine:3.20 sh -c "ls -la /shared && head -n 1 /shared/[0-9]* 2>/dev/null"

Остановка:

docker rm -f worker_1

Запуск 10 экземпляров

for i in $(seq 1 10); do
    docker run -d --name "worker_$i" -v shared-data:/shared concurrent-worker:1.0
done

Проверка: 

docker run --rm -v shared-data:/shared alpine:3.20 sh -c "head -n 1 /shared/[0-9]* 2>/dev/null"

Остановка:

docker rm -f $(docker ps -aq --filter "name=worker_")

Запуск 50 экземпляров:

for i in $(seq 1 50); do
    docker run -d --name "worker_$i" -v shared-data:/shared concurrent-worker:1.0
done

Проверка количества активных процессов и отсутствия сбоев:

docker ps | grep worker_ | wc -l
docker run --rm -v shared-data:/shared alpine:3.20 sh -c "head -n 1 /shared/[0-9]* 2>/dev/null"

Остановка и полная очистка:

docker rm -f $(docker ps -aq --filter "name=worker_")
docker volume rm shared-data


