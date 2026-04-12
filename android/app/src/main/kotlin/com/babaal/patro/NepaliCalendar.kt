package com.babaal.patro

import java.util.Calendar
import java.util.GregorianCalendar
import java.util.TimeZone

/**
 * Converts Gregorian (AD) dates to Bikram Sambat (BS) dates natively.
 * Port of the nepali_utils Dart package algorithm (same as the iOS Swift version).
 * Reference: BS 1970/1/1 = AD 1913/4/13
 */
object NepaliCalendar {
    val kathmanduTZ: TimeZone = TimeZone.getTimeZone("Asia/Kathmandu")

    data class BSDate(
        val year: Int,
        val month: Int,
        val day: Int,
        val weekday: Int // 1=Sunday … 7=Saturday
    )

    val monthNames = arrayOf(
        "बैशाख", "जेठ", "असार", "श्रावण", "भदौ", "असोज",
        "कार्तिक", "मंसिर", "पौष", "माघ", "फाल्गुन", "चैत्र"
    )

    val dayFullNames = arrayOf(
        "आइतबार", "सोमबार", "मंगलबार", "बुधबार",
        "बिहिबार", "शुक्रबार", "शनिबार"
    )

    private val nepaliDigits = charArrayOf('०', '१', '२', '३', '४', '५', '६', '७', '८', '९')

    private val adMonthNames = arrayOf(
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    )

    /** Convert the current Kathmandu time to a BS date. */
    fun now(): BSDate {
        val cal = GregorianCalendar(kathmanduTZ)
        return fromAD(
            year = cal.get(Calendar.YEAR),
            month = cal.get(Calendar.MONTH) + 1,
            day = cal.get(Calendar.DAY_OF_MONTH),
            weekday = cal.get(Calendar.DAY_OF_WEEK) // Calendar.SUNDAY=1
        )
    }

    /** Integer → Devanagari numeral string. */
    fun toNepaliNumeral(number: Int): String {
        return number.toString().map { ch ->
            if (ch.isDigit()) nepaliDigits[ch.digitToInt()] else ch
        }.joinToString("")
    }

    /** Format today's AD date as "Month Day, Year" in Kathmandu timezone. */
    fun formatADDate(): String {
        val cal = GregorianCalendar(kathmanduTZ)
        val month = adMonthNames[cal.get(Calendar.MONTH)]
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val year = cal.get(Calendar.YEAR)
        return "$month $day, $year"
    }

    /** Core AD → BS conversion (same algorithm as nepali_utils). */
    private fun fromAD(year: Int, month: Int, day: Int, weekday: Int): BSDate {
        var bsYear = 1970
        var bsMonth = 1
        var bsDay = 1

        val utc = TimeZone.getTimeZone("UTC")
        val refCal = GregorianCalendar(utc).apply { set(1913, Calendar.APRIL, 13, 0, 0, 0) }
        val targetCal = GregorianCalendar(utc).apply { set(year, month - 1, day, 0, 0, 0) }

        var diff = ((targetCal.timeInMillis - refCal.timeInMillis) / (24 * 60 * 60 * 1000)).toInt()

        if (diff < 0) {
            return BSDate(bsYear, bsMonth, bsDay, weekday)
        }

        // Advance BS year
        while (true) {
            val yd = nepaliYears[bsYear] ?: break
            if (diff < yd[0]) break
            diff -= yd[0]
            bsYear++
        }

        // Advance BS month
        while (bsMonth <= 12) {
            val yd = nepaliYears[bsYear] ?: break
            if (diff < yd[bsMonth]) break
            diff -= yd[bsMonth]
            bsMonth++
        }

        bsDay += diff
        return BSDate(bsYear, bsMonth, bsDay, weekday)
    }

    // Each entry: [totalDaysInYear, month1, month2, …, month12]
    // Source: nepali_utils 3.0.8
    private val nepaliYears: Map<Int, IntArray> = mapOf(
        1970 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1971 to intArrayOf(365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        1972 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        1973 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        1974 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1975 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        1976 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        1977 to intArrayOf(365, 30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        1978 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1979 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        1980 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        1981 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        1982 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1983 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        1984 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        1985 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        1986 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1987 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        1988 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        1989 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        1990 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1991 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        1992 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        1993 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        1994 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1995 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        1996 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        1997 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        1998 to intArrayOf(365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        1999 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2000 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2001 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2002 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2003 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2004 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2005 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2006 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2007 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2008 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        2009 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2010 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2011 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2012 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2013 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2014 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2015 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2016 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2017 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2018 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2019 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2020 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2021 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2022 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        2023 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2024 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2025 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2026 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2027 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2028 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2029 to intArrayOf(365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        2030 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2031 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2032 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2033 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2034 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2035 to intArrayOf(365, 30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        2036 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2037 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2038 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2039 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2040 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2041 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2042 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2043 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2044 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2045 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2046 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2047 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2048 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2049 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        2050 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2051 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2052 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2053 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        2054 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2055 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2056 to intArrayOf(365, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        2057 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2058 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2059 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2060 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2061 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2062 to intArrayOf(365, 30, 32, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31),
        2063 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2064 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2065 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2066 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        2067 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2068 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2069 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2070 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2071 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2072 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2073 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2074 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2075 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2076 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        2077 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2078 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        2079 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2080 to intArrayOf(365, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        2081 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2082 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2083 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2084 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2085 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2086 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2087 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2088 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2089 to intArrayOf(365, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        2090 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2091 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2092 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2093 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31),
        2094 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2095 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2096 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        2097 to intArrayOf(365, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        2098 to intArrayOf(365, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        2099 to intArrayOf(365, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        2100 to intArrayOf(366, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31)
    )
}
