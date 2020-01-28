
#include "olcConsoleGameEngine.h"



class olcEngine3D : public olcConsoleGameEngine
{

	int cartesianCenterX = 100;
	int cartesianCenterY = 100;
public:
	olcEngine3D()
	{
		m_sAppName = L"3D Demo";
	}

public:
	bool OnUserCreate() override
	{
		return true;
	}

	bool OnUserUpdate(float fElapsedTime) override
	{
		Fill(0, 0, ScreenWidth(), ScreenHeight(), PIXEL_SOLID, FG_BLACK); //  resets screen with black colour
		bresLine(0, 0, windowToCartesian(m_mousePosX, true), windowToCartesian(m_mousePosY, false)); // this is the line that points towards the mouse position
		// these lines are meant to be axises
		bresLine(0, windowToCartesian(0, false), 0, windowToCartesian(ScreenHeight(), false));
		bresLine(windowToCartesian(0, true), 0, windowToCartesian(ScreenWidth(), true), 0);
		// this colours the origin red
		Draw(cartesianCenterX, cartesianCenterY, 0x2588, 0x0004);
		//trashLine(100, 100, m_mousePosX, m_mousePosY);
		return true;
	}

	void bresLine(int x1, int y1, int x2, int y2)
	{
		int dx, dy, x, y, x_end, p;
		float m;

		dx = abs(x1 - x2); // finds the positive difference between x and y
		dy = abs(y1 - y2);
		p = 2 * dy - dx;

		// this sets which direction the line is going to draw
		if (dx != 0)
			m = dy / dx;
		else
			m = 1000;
		if (x1 > x2) {
			x = x2;
			y = y2;
			x_end = x1;
		}
		else {
			x = x1;
			y = y1;
			x_end = x2;
		}

		// this draws the origin of the line
		Draw(cartesianToWindow(x, true), cartesianToWindow(y, false));

		while (x < x_end) // basically for the length of the line
		{
			
			if (m < 1) // attempt and dividing by quadrants
			{
				x += 1; // steps forward one pixel to the right
				if (p < 0)
					// this means that the line is closer to the lower pixel, so it wont increase the y value for this x coordinate
					p += 2 * dy; // this line, and line 73, recaculate the new p value based off of the last p value
				else {
					// this means that the liner is closer to the upper pixel so it'll increase the y value before drawing the pixel
					p += 2 * (dy - dx);
					y += 1;
				}
			}
			else if (m >= 1)
			{
				y += 1;
				if (p < 0)
					p += 2 * dx;
				else {
					p += 2 * (dx - dy);
					x += 1;
				}
			}
			Draw(cartesianToWindow(x, true), cartesianToWindow(y, false)); // this draws the x,y coordinate for that step. This will repeat until the line is fully drawn

		} 
	}

	int windowToCartesian(int int1, bool isX)
	{
		if (isX)
			return int1 - cartesianCenterX;
		else
			return cartesianCenterY - int1;
	}

	int cartesianToWindow(int int1, bool isX)
	{
		if (isX)
			return int1 + cartesianCenterX;
		else
			return cartesianCenterY + int1;
	}

	void trashLine(int x1, int y1, int x2, int y2)
	{
		int dx, dy, steps;
		float x, y, m;
		dx = x2 - x1;
		dy = y2 - y1;
		if (abs(dx) > abs(dy))
			steps = abs(dx);
		else
			steps = (dy);
		if (dx != 0)
			m = dy / dx;
		else
			m = 1000;

		x = x1;
		y = y1;
		Draw(round(x), round(y));

		for (int k = 1; k <= steps; k++)
		{
			if (m >= 0 && m <= 1)
			{
				x += 1;
				y += m;
			}
			Draw(round(x), round(y));
		}
	}

	void trashestLine(int x1, int y1, int x2, int y2)
	{
		int x, y, x_end;
		float m;


	}
};


int main()
{
	olcEngine3D demo;
	if (demo.ConstructConsole(256, 240, 4, 4)) // this initialzes the console window
		demo.Start(); // if the window is properly created, the code will start
}

