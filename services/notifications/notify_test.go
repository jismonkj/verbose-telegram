package notifications

import "testing"

func TestNotify(t *testing.T) {
	tests := []struct {
		name string
	}{
		{
			"Notify",
		},
		{
			"Notify2",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			Notify()
		})
	}
}
