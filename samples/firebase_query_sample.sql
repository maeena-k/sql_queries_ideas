------------------------------------------------------------------
/**
 * Create temp functions for BigQuery
 * Declare the variables from manual input
 */
------------------------------------------------------------------

CREATE TEMP FUNCTION periodStartDate()  AS ('2020-04-07');       --> extract_start_date(yyyy-MM-dd)
CREATE TEMP FUNCTION periodEndDate()    AS ('2020-04-13');       --> campaign_end_date(yyyy-MM-dd)
CREATE TEMP FUNCTION cpStartDate()      AS ('2020-04-07');       --> campaign_start_date(yyyy-MM-dd)
CREATE TEMP FUNCTION cpCode()           AS ('sample');           --> campaign_code

------------------------------------------------------------------
/**
 * WITH queries for callback
 */
------------------------------------------------------------------

WITH
all_in_cp_period AS (
  SELECT
    *
  FROM
    `sample_table_name`
  WHERE
    _table_suffix BETWEEN FORMAT_DATE('%E4Y%m%d', CAST(periodStartDate() AS DATE))   --< extract_start_date
                      AND FORMAT_DATE('%E4Y%m%d', CAST(periodEndDate() AS DATE))     --< extract_end_date
),

clicked_user AS (
  SELECT
    DISTINCT(user_pseudo_id)
  FROM
    all_in_cp_period,
    UNNEST(event_params) AS ep
  WHERE
    ep.value.string_value = cpCode()
),

registered_user AS (
  SELECT
    DISTINCT(user_id)
  FROM
    all_in_cp_period
  WHERE
        user_id IS NOT NULL
    AND Exists (
          SELECT
            user_pseudo_id
          FROM
          	clicked_user
          WHERE
          	clicked_user.user_pseudo_id = all_in_cp_period.user_pseudo_id
                )
),

-- set index num for who clicked first
clicked_user_summary1 AS (
  SELECT
    user_id,
    user_pseudo_id,
    device.operating_system AS os,
    event_timestamp,
    EXTRACT(DATE FROM timestamp_micros(user_first_touch_timestamp) AT TIME ZONE 'Asia/Tokyo') AS first_time,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp ASC, user_id ASC) AS row_num
  FROM
    all_in_cp_period,
    UNNEST(event_params) AS ep
  WHERE
    ep.value.string_value = cpCode() --< campaign_code
),

-- extract only those who clicked first
clicked_user_summary2 AS (
  SELECT
    *
  FROM
    clicked_user_summary1
  WHERE
    row_num = 1
),

-- Group 1: newcomers after the campaign started
new_dl_clicked_user AS (
  SELECT
    DISTINCT(user_pseudo_id),
    event_timestamp,
    os
  FROM
    clicked_user_summary2
  WHERE
        user_id IS NULL
    AND first_time >= CAST(cpStartDate() AS DATE) --> キャンペーン期間開始日以降
),

-- Group 2: downloaded app but no registered before the campaign
new_register_clicked_user AS (
  SELECT
    DISTINCT(user_pseudo_id),
    event_timestamp,
    os
  FROM
    clicked_user_summary2
  WHERE
        user_id IS NULL
    AND first_time < CAST(cpStartDate() AS DATE)  --> キャンペーン期間開始前日以前
),

-- Group 3: downloaded and registered already before the campaign
existing_clicked_user AS (
  SELECT
    DISTINCT(user_pseudo_id),
    event_timestamp,
    os
  FROM
    clicked_user_summary2
  WHERE
    user_id IS NOT NULL
),

new_dl_user AS (
  SELECT
    DISTINCT(user_id),
    device.operating_system AS os,
    1 AS group_num,
    n.event_timestamp AS event_timestamp
  FROM
    all_in_cp_period AS a
  INNER JOIN new_dl_clicked_user AS n
          ON n.user_pseudo_id = a.user_pseudo_id
         AND n.os = a.device.operating_system
  WHERE
    user_id IS NOT NULL
),

new_register_user AS (
  SELECT
    DISTINCT(user_id),
    device.operating_system AS os,
    2 AS group_num,
    n.event_timestamp AS event_timestamp
  FROM
    all_in_cp_period AS a
  INNER JOIN new_register_clicked_user AS n
          ON n.user_pseudo_id = a.user_pseudo_id
         AND n.os = a.device.operating_system
  WHERE
    user_id IS NOT NULL
),

existing_user AS (
  SELECT
    DISTINCT(user_id),
    device.operating_system AS os,
    3 AS group_num,
    e.event_timestamp AS event_timestamp
  FROM
    all_in_cp_period AS a
  INNER JOIN existing_clicked_user AS e
          ON e.user_pseudo_id = a.user_pseudo_id
         AND e.os = a.device.operating_system
  WHERE
    user_id IS NOT NULL
),

target_user_summary1 AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_timestamp) AS clicked_order
  FROM (
        SELECT * FROM new_dl_user
        UNION ALL
        SELECT * FROM new_register_user
        UNION ALL
        SELECT * FROM existing_user
        )
),

target_user_summary2 AS (
  SELECT
    user_id,
    group_num,
    os
  FROM
    target_user_summary1
  WHERE
    clicked_order = 1
),

--
group_num_summary AS (
  SELECT
    group_num,
    CASE
      WHEN os = 'IOS' THEN 1
      ELSE 0
    END AS ios_flag,
    CASE
      WHEN os = 'ANDROID' THEN 1
      ELSE 0
    END AS android_flag
  FROM
    target_user_summary2
)

------------------------------------------------------------------
/**
 * Queries for output
 * Remove Comment out to use the query
 */
------------------------------------------------------------------

/* 1. Clicked users list
SELECT
  user_pseudo_id
FROM clicked_user
*/

/* 2. Registered users list (Coupon Target Users)
SELECT
 *
FROM target_user_summary2
*/

/* 3. Daily Report (member status before the campaign x mobile os) */
SELECT
  DISTINCT(group_num),
  SUM(android_flag) OVER (PARTITION BY group_num) AS android_user_num,
  SUM(ios_flag) OVER (PARTITION BY group_num) AS ios_user_num
FROM
  group_num_summary
ORDER BY
  group_num ASC
