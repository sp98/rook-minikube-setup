package com.example.cowinalert

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.cowinalert.ui.theme.CowinAlertTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val application = requireNotNull(this).application
        val dataSource = AlertDatabase.getInstance(application).alertDatabaseDao
        val createAlertViewModelFactory = CreateAlertViewModelFactory(dataSource)
        val createAlertViewModel = ViewModelProvider(
            this,
            createAlertViewModelFactory
        ).get(CreateAlertViewModel::class.java)
        val alertViewModelFactory = AlertViewModelFactory(dataSource)
        val alertViewModel = ViewModelProvider(this, alertViewModelFactory).get(AlertViewModel::class.java)

        setContent {
            val navController = rememberNavController()
            NavHost(navController = navController, startDestination = "home"){
                composable("home"){
                    AlertScreen(viewModel = alertViewModel, navController = navController)
                }
                composable("createAlert"){
                    CreateAlertScreen(viewModel = createAlertViewModel, navController = navController)
                }
            }
//            CowinAlertTheme {
//                // A surface container using the 'background' color from the theme
//                Surface(color = MaterialTheme.colors.background) {
//
//
//                    AlertScreen(viewModel = alertViewModel)
//                }
//            }
        }
    }
}
