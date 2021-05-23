package com.example.cowinalert

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.navigation.NavController
import androidx.navigation.compose.navigate
import kotlinx.coroutines.*
import timber.log.Timber

class CreateAlertViewModel(
    val database: AlertDatabaseDao
) : ViewModel() {

    // ViewModel Job for coroutines
    private var viewModelJob = Job()

    override fun onCleared() {
        super.onCleared()
        // cancel all coroutines
        viewModelJob.cancel()
    }

    private val uiscope = CoroutineScope(Dispatchers.Main + viewModelJob)

    var name: String by mutableStateOf("")

    var pin: String by mutableStateOf("")

    var isCovishield: Boolean by mutableStateOf(false)

    var isCovaxin: Boolean by mutableStateOf(false)

    var isAbove45: Boolean by mutableStateOf(false)

    var isBelow45: Boolean by mutableStateOf(false)

    fun onNameChange(newName:String){
        Timber.i("name changing")
        name = newName
    }

    fun onPinChange(newPin:String){
        pin = newPin
    }

    fun onCovishieldCheck(covishield:Boolean){
        isCovishield = covishield
    }

    fun onCovaxinCheck(covaxin:Boolean) {
        isCovaxin = covaxin
    }

    fun onAbove45check(above45:Boolean){
        isAbove45 = above45
    }

    fun onBelow45Check(below45: Boolean){
        isBelow45 = below45
    }

    fun onCreate(navController: NavController){
        // create instance of alert data class
        val alert: Alert = Alert(
            name = name,
            pinCode = pin,
            isCovishield = isCovishield,
            isCovaxin = isCovaxin,
            above45 = isAbove45,
            below45 = isBelow45,
            )

        // save alert to database
        onInsert(alert)
        navController.navigate("Home")
    }

    private fun onInsert(alert:Alert){
        uiscope.launch {
            insert(alert)
        }
    }

    private suspend fun insert(alert: Alert){
        withContext(Dispatchers.IO){
            database.insert(alert)
            println("inserted")
        }
    }

}