package com.example.cowinalert

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material.Button
import androidx.compose.material.Checkbox
import androidx.compose.material.Text
import androidx.compose.material.TextField
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.navigation.compose.navigate
import timber.log.Timber

@Composable
fun CreateAlertScreen(
    viewModel: CreateAlertViewModel,
    navController: NavController
) {
    Column(Modifier.padding(24.dp)) {

        // alert name text field
        AlertTextField(
            value = viewModel.name,
            onValueChange = viewModel::onNameChange,
            placeholder = "Enter alert name"
        )

        // pin name text field
        AlertTextField(
            value = viewModel.pin,
            onValueChange = viewModel::onPinChange,
            placeholder = "Enter pincode"
        )

        // Covishield checkbox
        CheckboxComponent(
            checked = viewModel.isCovishield,
            onCheckedChange = viewModel::onCovishieldCheck,
            checkBoxText = "Covishield"
        )

        // Covaxin Checkbox
        CheckboxComponent(
            checked = viewModel.isCovaxin,
            onCheckedChange = viewModel::onCovaxinCheck,
            checkBoxText = "Covaxin"
        )

        // above 45 checkbox
        CheckboxComponent(
            checked = viewModel.isAbove45,
            onCheckedChange = viewModel::onAbove45check,
            checkBoxText = "Above 45"
        )

        // below 45 checkbox
        CheckboxComponent(
            checked = viewModel.isBelow45,
            onCheckedChange = viewModel::onBelow45Check,
            checkBoxText = "Below 45"
        )


        Button(
            enabled = viewModel.name.isNotEmpty() && viewModel.pin.isNotEmpty(),
            onClick = { viewModel.onCreate(navController) },
            modifier = Modifier
                .padding(8.dp)
                .align(Alignment.CenterHorizontally)
                .padding(24.dp)
        ) {
            Text(text = "Create")
        }
    }

}


@Composable
fun AlertTextField(value: String, onValueChange: (String) -> Unit, placeholder: String) {
    TextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(text = placeholder) }
    )
}

@Composable
fun CheckboxComponent(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    checkBoxText: String
) {

    Row(Modifier.padding(top = 8.dp)) {
        Text(text = checkBoxText)
        Checkbox(
            checked = checked,
            onCheckedChange = onCheckedChange,
            Modifier.padding(start = 10.dp)
        )
    }
}


@Preview(name = "Create Alert")
@Composable
fun PreviewCreateAlertScreen() {
    //CreateAlertScreen(CreateAlertViewModel())
}