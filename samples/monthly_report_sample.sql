-------------------------------------------
/*
 * Declare variables of the period range (str)
 */
-------------------------------------------
WITH temp_variables AS (
	SELECT
		'20200801' AS startDateStr,
		'20200831' AS endDateStr
),

-------------------------------------------
/*
 * WITH queries for callback
 */
-------------------------------------------

coupon_used_users AS (
	SELECT
		coupon_id,
    CASE
      WHEN SUBSTRING(coupon_id, 9, 1) = 'C' THEN '1_campaign'
      WHEN SUBSTRING(coupon_id, 9, 1) = 'W' THEN '2_welcome'
      WHEN SUBSTRING(coupon_id, 9, 1) = 'S' THEN '3_stamp'
      WHEN SUBSTRING(coupon_id, 9, 1) = 'G' THEN '4_game'
      ELSE '5_other'
    END AS coupon_category,
		member_id,
		CASE
			WHEN used_status = 2 THEN 1
			ELSE 0
		END AS used_flag
	FROM
		coupon_histories
	WHERE
		LEFT(created_timestamp, 8) >= (SELECT startDateStr FROM temp_variables)
	 AND	LEFT(created_timestamp, 8) <= (SELECT endDateStr FROM temp_variables)
),

coupon_sum_max_users AS (
	SELECT
		coupon_id,
    coupon_category,
		member_id,
		COUNT(*) AS delivery_coupon_num,
		MAX(used_flag) AS used_member_flag,
		SUM(used_flag) AS used_coupon_num
	FROM
		coupon_use
	GROUP BY
		coupon_id, member_id
)

-------------------------------------------
/*
 * For monthly report of coupon usage
 */
-------------------------------------------
SELECT
	coupon_id,
  coupon_category,
	COUNT(*) AS delivery_coupon_uu,
	SUM(delivery_coupon_num) AS sum_delivery_coupon_num,
	SUM(used_member_flag) AS used_coupon_uu,
	SUM(used_coupon_num) AS sum_used_coupon_num
FROM
	coupon_sum_max_users
GROUP BY
	coupon_id
ORDER BY
	coupon_id
;