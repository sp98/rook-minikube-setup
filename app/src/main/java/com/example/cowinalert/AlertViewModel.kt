package com.example.cowinalert

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.*

class AlertViewModel(
    val database: AlertDatabaseDao
) : ViewModel() {

    private val viewModelJob = Job()
    private val uiscope = CoroutineScope(Dispatchers.Main + viewModelJob)

    var alerts by mutableStateOf(listOf<Alert>())
        private set

    init {
        initialize()
    }

    private fun initialize() {
        uiscope.launch {
            initializeAlerts()
        }
    }

    private suspend fun initializeAlerts(){
        withContext(Dispatchers.IO){
            alerts = database.getAllAlerts()
        }
    }
}