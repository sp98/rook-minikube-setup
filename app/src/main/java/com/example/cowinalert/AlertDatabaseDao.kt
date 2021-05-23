package com.example.cowinalert

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface AlertDatabaseDao {
    @Insert
    fun insert(alert: Alert)

    @Query("SELECT * FROM cowin_alert_table ORDER BY  alertID DESC")
    fun getAllAlerts(): List<Alert>
}