package c1

import "fmt"

func C1Helper(mode int) {
	fmt.Println("Inside c1Helper")
	switch mode {
	case 1:
		fmt.Println("mode 1")
	case 2:
		fmt.Println("mode 2")
	default:
		fmt.Println("mode unknown")
	}
}
