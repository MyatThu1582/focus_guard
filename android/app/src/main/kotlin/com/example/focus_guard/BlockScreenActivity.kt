package com.example.focus_guard

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

class BlockScreenActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this)

        layout.orientation = LinearLayout.VERTICAL
        layout.gravity = Gravity.CENTER
        layout.setBackgroundColor(Color.WHITE)

        val title = TextView(this)

        title.text = "Focus Guard"
        title.textSize = 32f
        title.setTextColor(Color.BLACK)
        title.gravity = Gravity.CENTER

        val message = TextView(this)

        message.text = "\nThis app is currently blocked."
        message.textSize = 20f
        message.setTextColor(Color.DKGRAY)
        message.gravity = Gravity.CENTER

        layout.addView(title)
        layout.addView(message)

        setContentView(layout)
    }
}