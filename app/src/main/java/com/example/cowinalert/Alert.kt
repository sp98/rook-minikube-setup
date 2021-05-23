package com.example.cowinalert

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "cowin_alert_table")
data class Alert(

    @PrimaryKey(autoGenerate = true)
    val alertID:Long = 0L,

    @ColumnInfo(name = "alert_name")
    val name: String,

    @ColumnInfo(name= "pincode")
    val pinCode: String,

    @ColumnInfo(name= "isCovishield")
    val isCovishield: Boolean = false,

    @ColumnInfo(name = "isCovaxin")
    val isCovaxin: Boolean = false,

    @ColumnInfo(name = "above45")
    val above45: Boolean = false,

    @ColumnInfo(name = "below45")
    val below45: Boolean = false,
)