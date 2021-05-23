package com.example.cowinalert

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.Button
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.navigate


@Composable
fun AlertScreen(
    viewModel: AlertViewModel,
    navController: NavController
){
    Column(){
        AlertList(viewModel.alerts)
        Button(
            onClick = {navController.navigate("CreateAlert")},
            modifier = Modifier
                .padding(8.dp)

        ){
            Text("Create")
        }
    }

}

@Composable
fun AlertList(alerts:List<Alert>){
    LazyColumn(
        contentPadding = PaddingValues(top=8.dp)
    ) {
        items(items = alerts){ alert ->
            Text(text = alert.name)
        }
    }

}


@Preview(name = "Alert List")
@Composable
fun PreviewHomeScreen(){
    val alerts = listOf(
        Alert(name="alert1", pinCode = "123"),
        Alert(name="alert2", pinCode = "123"),
        Alert(name="alert3", pinCode = "123"),
    )
    AlertList(alerts)
}