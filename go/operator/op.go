package main

import "fmt"

func main() {
	/*
					var a int
					a = 4
					b := 2

					fmt.Printf("%v\n", a&b)
					fmt.Printf("%v\n", a|b)
					fmt.Println("result =", a^b)


				a := 21
				c := a % 10
				a = a / 10
				d := a % 10

				fmt.Printf("첫번째 수 : %v 두번째 수 : %v\n", c, d)

			a := 4

			fmt.Println(a << 1)
			fmt.Println(a >> 1)

		var a bool
		a = 3 > 4 && 2 < 5

		fmt.Println(a)
	*/

	a := 5
	if a == 3 {
		fmt.Println("a 는 3")
	} else if a == 4 {
		fmt.Println("a 는 4")
	} else if a < 10 && a > 2 {
		fmt.Println("a는 10보다 작고 2보다 크다")
	} else {
		fmt.Println("a 는 3과 4가 아니다")
	}
	fmt.Println("a 의 값은 ", a, "이다")

}
