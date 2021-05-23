package com.example.cowinalert

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [Alert::class], version=1, exportSchema=false)
abstract class AlertDatabase : RoomDatabase() {

    abstract val alertDatabaseDao: AlertDatabaseDao

    companion object{
        @Volatile
        private var INSTANCE: AlertDatabase?= null

        fun getInstance(context: Context) : AlertDatabase{
            synchronized(this){
                var instance = INSTANCE
                if (instance == null){
                    instance = Room.databaseBuilder(
                        context.applicationContext,
                        AlertDatabase::class.java,
                        "cowin_alert_database"
                    )
                        .fallbackToDestructiveMigration()
                        .build()
                    INSTANCE = instance
                }
                return instance
            }
        }
    }
}