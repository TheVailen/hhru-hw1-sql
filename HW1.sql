-- ============================================================
-- Домашнее задание к лекции «SQL. Введение»
-- Школа Аналитиков · учебная база hh_school
-- Автор: [Лобачёв Андрей Александрович]
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================

SET search_path TO hh_school;


-- ============================================================
-- БЛОК А. Разминка: термины и структура (текстом)
-- ============================================================

-- ЗАДАНИЕ А1
-- 1. Категория и конкретный тип колонок:
--    vacancies.salary_from        — категория: числовые   тип: int
--    vacancies.vacancy_name       — категория: строковые   тип: text
--    vacancies.published_at       — категория: дата и время   тип: timestamp
--    employers.is_accredited_it   — категория: логические   тип: boolean
--    responses.created_at         — категория: дата и время   тип: timestamp
--
-- 2. Первичные ключи таблиц:
--    areas: area_id
--    employers: employer_id
--    vacancies: vacancy_id
--    vacancy_details: vacancy_id (чем особенный: это одновременно и PK, и FK, ссылается на vacancies)
--    responses: response_id
--
-- 3. Почему vacancy_name не может быть первичным ключом:
--    Так как 
--    Запрос для подтверждения числом:
    SELECT vacancy_name, count(*)
    FROM hh_school.vacancies 
    GROUP BY vacancy_name
    ORDER BY count(*) DESC
    LIMIT 1;

-- запрос:
-- Группируем вакансии по названию, считаем их количество и выводим самое частое с помощью DESC и LIMIT 1
-- Вывод:
-- Запрос показал, что самая частая вакансия - стажёр-аналитик, которая повторяется 6 раз. Первичные ключи должны быть уникальными, а у нас 6 одинаковых PK - противоречие.
--
-- 4. Что произойдёт при записи строки «по договорённости» в salary_from:
-- СУБД откажется принимать строку в числовую категорию (int). Такое поведение СУБД хорошо тем, что колонки типизированы, значит их поведение предсказуемо. Мы ожидаем, что сможем отсортировать вакансии по зарплате с каким-либо заданным условием (например: >70000). Если бы можно было писать в salary_from что угодно, тогда кто-то бы писал "по договорённости", а кто-то числа, и получилась бы неразбериха. Совет работодателю: либо оставить значение NULL в salary_from, либо создать отдельную колонку salary_message категории строковые, и записать комментарий туда.


-- ============================================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================

-- ЗАДАНИЕ Б1
-- Запрос: experience
    SELECT DISTINCT experience
    FROM vacancies
    ORDER BY experience;


-- Запрос: employment
    SELECT DISTINCT employment
    FROM vacancies
    ORDER BY employment;


-- Запрос: professional_role
    SELECT DISTINCT professional_role
    FROM vacancies
    ORDER BY professional_role;


-- Вывод:
-- В колонке experince 3 различных значения (От 3 до 6 лет, Нет опыта, От 1 года до 3 лет), в employment также 3 различных значения (Частичная занятость, Стажировка, Полная занятость), в professional_role 5 уникальных значений (Дата-инженер, Разработчик, Продуктовый аналитик, Аналитик данных, Тестировщик). Дубликатов, написанных в разном регистре, нет; NULL тоже не обнаружено. 


-- ЗАДАНИЕ Б2
-- Запрос 1: стажировки в Москве без опыта, вакансия открыта
    SELECT v.vacancy_id, v.vacancy_name, v.salary_from, v.published_at
    FROM vacancies v
    INNER JOIN areas a ON v.area_id = a.area_id
    WHERE v.employment = 'Стажировка' 
        AND v.experience = 'Нет опыта' 
        AND v.closed_at IS NULL
        AND a.area_name = 'Москва'
    ORDER BY v.published_at DESC;


-- Запрос 2: топ-10 вакансий по salary_from
    SELECT vacancy_name, professional_role, salary_from
    FROM vacancies
    ORDER BY salary_from DESC NULLS LAST
    LIMIT 10;

-- Вывод:
-- Первый запрос нашёл 8 вакансий. Если убрать условие про Москву, то, во-первых, реализация станет гораздо легче, потому что не надо будет делать JOIN, а во-вторых, число вакансий увеличится до 10. Можно было и так обойтись без JOIN, но тогда надо было делать отдельный запрос к табличке areas, чтобы узнать ID Москвы, и явно сравнивать v.area_id с этим числом.
--


-- ЗАДАНИЕ Б3
-- Ловушка 1. NULL — выполнить и объяснить результат
SELECT count(*) FROM vacancies WHERE closed_at = NULL;
SELECT count(*) FROM vacancies WHERE closed_at IS NULL;

-- Ловушка 2. AND / OR — выполнить и объяснить результат
SELECT count(*) FROM vacancies
WHERE area_id = 1 OR area_id = 2 AND experience = 'Нет опыта';

SELECT count(*) FROM vacancies
WHERE (area_id = 1 OR area_id = 2) AND experience = 'Нет опыта';

-- Вывод:
-- 1) Потому что сравнение с NULL никогда не истинно. Выполнение запроса без ошибки опасно тем, что при невнимательности можно пропустить этот недочёт и брать в расчёт нерелевантные данные. NULL в колонке closed_at означает, что дата закрытия вакансии отсутствует, соответственно вакансия открыта и на неё продолжается набор кандидатов.
-- 2) База прочитала первое условие так: сначала взяла AND (логическое умножение), уже после OR (логическое ИЛИ). Нашла вакансии с id = 2 и "Нет опыта", затем соединила их с условием "или" при id = 1. На вопрос, поставленный в этом условии, отвечает второй запрос.


-- ============================================================
-- БЛОК В. Агрегации и метрики
-- ============================================================

-- ЗАДАНИЕ В1
-- Запрос 1: счётчики (строки, зарплата указана, направления, работодатели)
    SELECT count(*) AS lines, count(salary_from) AS count_vacancies, count(DISTINCT professional_role) AS role, count(DISTINCT employer_id) AS employers
    FROM vacancies;


-- Запрос 2: доля активных вакансий (без JOIN)
    SET search_path = hh_school;
    SELECT 
        count(*) - count(closed_at) AS open_vacancies,
        count(closed_at) AS closed_vacancies,
        round((count(*) - count(closed_at)) * 100.0 / count(*), 1) AS open_percentage
    FROM vacancies;

-- Вывод:
-- count(*) считает все строки с учётом NULL - их 52; 
-- count(колонка) считает строки без учёта NULL - например, count(closed_at) в запросе 2 считает количество строк, где точно записана дата закрытия вакансии, их 19, NULL тут нет; 
-- count(DISTINCT колонка) считает уникальные значения строк без учёта NULL - count(DISTINCT professional_role) в запросе 1 считает различные направления, их 5

-- «Сейчас у нас открыто 33 вакансии, их доля от всех вакансий составляет 63.5%»


-- ЗАДАНИЕ В2
-- Запрос 1: направления — вакансии, работодатели, средняя зарплата
    SELECT 
        professional_role,
        count(*) AS vacancies_count,
        count(DISTINCT employer_id) AS employers_count,
        round(avg(salary_from)) AS avg_salary
    FROM vacancies
    GROUP BY professional_role
    ORDER BY count(*) DESC;


-- Запрос 2: то же, только направления с ≥ 5 открытыми вакансиями (WHERE + HAVING)
    SELECT 
        professional_role,
        count(*) AS vacancies_count,
        count(DISTINCT employer_id) AS employers_count,
        round(avg(salary_from)) AS avg_salary
    FROM vacancies
    WHERE closed_at IS NULL
    GROUP BY professional_role
    HAVING count(*) >= 5
    ORDER BY count(*) DESC;

-- Вывод:
-- Больше половины вакансий рынка занимают «Аналитик данных» и «Разработчик». Соискатель на основе этих данных бы решил, что нужно откликаться именно на эти вакансии, но здесь не учитывается конкуренция. Для представления полной картины стоит рассматривать ещё и responses.
-- «Только открытые вакансии» пишется в WHERE, потому что здесь мы работаем ещё с каждой строкой отдельно. После формируем строки в группы по professional_role, уже после применяем агрегатную функцию в HAVING. WHERE не дружит с агрегатными функциями, поэтому произошла бы ошибка. 
-- Найденное avg(salary_from) отвечает на вопрос: «Какая средняя нижняя граница?», мы не учитываем salary_to, поэтому вовсе не можем сказать, сколько в среднем зарабатывают специалисты. Тем более avg не учитывает NULL значения, поэтому, если в вакансии не будет указана вилка зарплат, то это значение мы просто не учтём.

-- ============================================================
-- БЛОК Г. Соединение таблиц
-- ============================================================

-- ЗАДАНИЕ Г1
-- Запрос: топ-5 по salary_from с названием компании и городом (псевдонимы таблиц)
    SELECT v.vacancy_name, e.employer_name, a.area_name, v.salary_from
    FROM vacancies v
    INNER JOIN employers e 
        ON v.employer_id = e.employer_id
    INNER JOIN areas a
        ON v.area_id = a.area_id
    ORDER BY v.salary_from DESC
        NULLS LAST
    LIMIT 5;


-- Вывод:
-- area_id встречается в нашей БД в 3-х таблицах. СУБД не сможет понять, к какой таблице обратиться, чтобы взять нужный нам area_id. Поэтому нужно явно указывать псевдоним таблицы вместе с колонкой, чтобы избежать неопределённости. База ответит «column reference is ambiguous»
--


-- ЗАДАНИЕ Г2
-- Запрос 1: все работодатели, число вакансий и откликов (LEFT JOIN)
    SELECT e.employer_name, count(DISTINCT v.vacancy_id) AS count_vacancies, count(r.response_id) AS count_responses
    FROM employers e
    LEFT JOIN vacancies v
        ON e.employer_id = v.employer_id
    LEFT JOIN responses r
        ON v.vacancy_id = r.vacancy_id
    GROUP BY employer_name
    ORDER BY count(r.response_id) DESC;


-- Запрос 2: тот же запрос с INNER JOIN
    SELECT e.employer_name, count(DISTINCT v.vacancy_id) AS count_vacancies, count(r.response_id) AS count_responses
    FROM vacancies v
    INNER JOIN employers e
        ON  v.employer_id = e.employer_id 
    INNER JOIN responses r
        ON v.vacancy_id = r.vacancy_id
    GROUP BY employer_name
    ORDER BY count(r.response_id) DESC;

-- Запрос 3: проверка «ГринЭнерго»
    SET search_path = hh_school;
    SELECT e.employer_name, v.vacancy_name, v.published_at, v.closed_at
    FROM employers e
    INNER JOIN vacancies v 
        ON e.employer_id = v.employer_id
    WHERE e.employer_name = 'ГринЭнерго';


-- Вывод:
-- 1) Потому что после JOIN с таблицей откликов у нас будет склеенная таблица, в которой дублируются строки с одной и той же вакансией столько раз, сколько раз на неё откликнулись. Надо считать уникальные значения через count(DISTINCT v.vacancy_id).
-- 2) Исчезла компания «ГринЭнерго», потому что INNER JOIN оставляет только совпадения. В данном случае это содержательная потеря, ведь отчёт готовится для встречи с работодателями-партнёрами, а «ГринЭнерго» не получает откликов. Вакансия была открыта «2026-04-06», закрыта «2026-05-04». Это значит, что вакансия провисела почти месяц, не собрав ни одного отклика. Здесь уже можно предположить об их неверной стратегии, которую стоит обсудить. 
-- 3) LEFT JOIN использовать, когда нужны все значения из искомой таблицы, при несовпадении с другими таблицами колонка остаётся, но обнуляется. В данном кейсе это критично. Если нужно отбрасывать нулевые значения, то используем INNER JOIN.


-- ============================================================
-- БЛОК Д. Функции и финальный кейс
-- ============================================================

-- ЗАДАНИЕ Д1
-- Запрос 1: помесячная динамика откликов и конверсия
-- (месяц как дата, условный агрегат, nullif в знаменателе)
    SELECT 
        date_trunc('month', "created_at")::date AS month,
        count(response_id) AS count_responses, 
        count(response_id) FILTER (WHERE status = 'invited') AS invited, 
        round(100.0 * count(response_id) FILTER (WHERE status = 'invited') / nullif(count(response_id), 0), 1) AS conversion_pct
    FROM responses
    GROUP BY 1
    ORDER BY MONTH;

-- Запрос 2: последняя дата отклика (чтобы проверить гипотезу по августу)
    SELECT max(created_at) AS last_response_date
    FROM responses;

-- Вывод:
-- 1) Максимальная конверсия в июне - она составила 19.5%. 
-- 2) Да, этому месяцу можно доверять, потому что в нём было 118 откликов и 23 приглашённых. По числу откликов это топ-2 месяц, первый - июль со 142 откликами, но приглашённых в нём 18.
-- 3) У последнего месяца конверсия отклика в приглашения составляет 7.3%, это значительно меньше остальных месяцев. Число откликов - 41, но приглашено всего 3 человека. Гипотеза: Возможно месяц ещё не завершился, и процесс найма продолжается. Добавил запрос 2 для поиска последнего отклика, он показал последнюю дату отклика: «2026-08-15» Это середина августа, значит процесс фидбэка ещё не завершён, отклики просто не успели стать приглашениями на работу. 
-- ЗАДАНИЕ Д2
-- Запрос: таблица по направлениям (вакансии, отклики, приглашения,
-- откликов на вакансию, конверсия)
    SELECT 
        v.professional_role,
        count(DISTINCT v.vacancy_id) AS count_vacancies,
        count(r.response_id) AS count_responses, 
        count(r.response_id) FILTER (WHERE r.status = 'invited') AS invited, 
        round(1.0 * count(r.response_id) / nullif(count(DISTINCT v.vacancy_id), 0), 1) AS avg_responses,
        round(100.0 * count(r.response_id) FILTER (WHERE r.status = 'invited') / nullif(count(r.response_id), 0), 1) AS conversion_pct
    FROM vacancies v
    LEFT JOIN responses r
        ON v.vacancy_id = r.vacancy_id
    GROUP BY v.professional_role
    ORDER BY count_vacancies DESC;



-- Письменные ответы:
-- 1. Совпадает ли направление с наибольшим числом вакансий с направлением
--    с наибольшей конверсией?
-- Нет, не совпадает. Наибольшее число вакансий по специальности «Аналитик данных» - 16, а наибольшая конверсия у роли «Тестировщика» - 35.9%, поэтому не стоит слепо доверять числу вакансий по специальности.

-- 2. Какое направление выбрать и почему (опираясь на два столбца):
-- Однозначно стоит выбирать направление «Тестировки». Низкая конкуренция - в среднем всего 5.6 откликов на вакансию c конверсией 35.9%. Только на «Дата-инженера» в среднем меньше откликов - 4.9, но при этом конверсия в 3 с лишним раза меньше - 11.8%

-- 3. Оговорка к выводу:
-- Друг ищет стажировку, а здесь таблица не учитывает опыт, поэтому грейды специальностей смешались. Стоит добавить проверку: WHERE v.experience = 'Нет опыта'

-- ============================================================
-- БЛОК Е. Со звёздочкой
-- ============================================================

-- ЗАДАНИЕ Е1
-- Исходный запрос (выполнить и посмотреть результат):
-- SELECT v.professional_role,
-- count(*) AS vacancies,
-- sum(v.salary_from) AS total_salary,
-- count(r.response_id) / count(*) AS responses_per_vacancy
-- FROM vacancies v
-- JOIN responses r ON v.vacancy_id = r.vacancy_id
-- WHERE v.closed_at = NULL
-- GROUP BY 1;
--
-- Ошибки (минимум четыре):
-- 1. WHERE v.closed_at = NULL // надо IS NULL
-- 2. JOIN // надо LEFT JOIN, потому что иначе отбросятся открытые вакансии
-- 3. count(*) // надо count(DISTINCT v.vacancy_id)
-- 4. count(r.response_id) / count(*) // во-первых, знаменатель должен быть как в ошибке 3, во-вторых, деление целого числа (count) на целое число (count) отбросит остаток, и метрика превратится в ноль
-- 5. sum(v.salary_from) AS total_salary // Из-за JOIN таблица размножилась: если на вакансию с зарплатой 100к пришло 20 откликов, её строка продублируется 20 раз, и сумма даст 2 млн руб. Кроме того, "сумма нижних границ зарплат" показыввает, насколько «масштабно» направление, то есть сколько работодатели готовы платить в этом направлении. Более подходящая метрика - средняя зарплата (avg). Важно!!! : из-за JOIN даже функция avg сместит значение в сторону зарплат более популярных вакансий (которые получают больше откликов), но базово замена sum на avg делает метрику намного более адекватной.

-- Исправленный запрос:
    SELECT 
        v.professional_role,
        count(DISTINCT v.vacancy_id) AS vacancies,
        round(avg(v.salary_from)) AS avg_salary,
        round(1.0 * count(r.response_id) / nullif(count(DISTINCT v.vacancy_id), 0), 1) AS responses_per_vacancy
    FROM vacancies v
    LEFT JOIN responses r 
        ON v.vacancy_id = r.vacancy_id
    WHERE v.closed_at IS NULL
    GROUP BY 1;
-- Какие два правила из лекции защитили бы от этих ошибок при написании запроса:
-- 1. MUUUUUST HAVE: Выполнять запрос по мере написания логических блоков. Так проще заметить ошибку сразу, а не копаться в скрипте потом
-- 2. Проверка NULL всегда через IS !!! 
