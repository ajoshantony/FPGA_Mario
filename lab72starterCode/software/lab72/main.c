
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "text_mode_vga_color.h"


int main(){
	while(1){
		paletteTest();
		textVGAColorScreenSaver();
	}
	return 0;
}
