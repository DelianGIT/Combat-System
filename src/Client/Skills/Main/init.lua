return {
	Punch = {
		Keybind = {
			Key = Enum.UserInputType.MouseButton1,
			State = "Begin",
		},
	},

	Block = {
		Keybind = {
			Key = Enum.KeyCode.F,
			State = "Begin",
		},

		HasEnd = true,
	},

	Dash = {
		Keybind = {
			Key = Enum.KeyCode.Q,
			State = "Begin",
		},
	},

	Sprint = {
		Keybind = {
			Key = Enum.KeyCode.W,
			State = "DoubleClick",
			ClickFrame = 0.25,
		},

		HasEnd = true,
	},
}
