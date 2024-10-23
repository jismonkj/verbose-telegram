package main

import (
	"github.com/jismonkj/verbose-telegram/services/helper"
	"github.com/jismonkj/verbose-telegram/services/notifications"
)

func main() {
	helper.Helper()
	notifications.Notify()
}
