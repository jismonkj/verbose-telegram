package c1

import "fmt"

func C1Helper(mode int) {
	fmt.Println("Inside c1Helper")
	switch mode {
	case 1:
		fmt.Println("mode 1")
	default:
		fmt.Println("mode unknown")
	}
}
