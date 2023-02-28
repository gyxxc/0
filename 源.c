#include<stdio.h>
#include<stdlib.h>
#include<time.h>

int arr[] = { 20,12,15,19,13,14,18,10,8,1,11,2,5,4,3,7,17,6,9,16 };
int sum(int array[], int n) {
	int tmp=0;
	for (int i = 0; i < n; i++) {
		tmp = tmp + array[i]*array[i];
	}
	return tmp;
}//求和算法
int selct1(int arr[], int n) {
	for (int i = 0; i < n - 1; i++) {
		for (int j = i + 1; j < n; j++) {
			if (arr[i] > arr[j]) {
				int tmp;
				tmp = arr[i];
				arr[i] = arr[j];
				arr[j] = tmp;
			}
		}
	}
	return arr;
}//选择排序
int selct2(int arr[], size_t n) {
	int** tmp = (int**)malloc(sizeof(int) * 10);
	for (int i = 0; i < 10; i++) {
		tmp[i] = (int*)malloc(sizeof(int) * n);
	}
	for (int i = 1; i <= 100; i *= 10) {
		for (int x = 0; x < 10; ++x) {
			for (int y = 0; y < n; ++y) {
				tmp[x][y] = -1;
			}
		}
		for (int m = 0; m < n; ++m) {
			int index = (arr[m] / i) % 10;
			tmp[index][m] = arr[m];
		}
		int k = 0;
		for (int x = 0; x < 10; x++) {
			for (int y = 0; y < n; ++y) {
				if (tmp[x][y] != -1)
					arr[k++] = tmp[x][y];
			}
		}
	}
	for (int i = 0; i < 10; i++) {
		free(tmp[i]);
	}
	free(tmp);
}
int main() {
	clock_t start1, end1, start2, end2;
	int arr1[20];
	srand((unsigned)time(NULL));
/*	for (int i = 0; i < 20; i++)
		arr1 = arr1 + {rand()};
*/
	printf("sum=%d\n", sum(arr1, 20));
	start1 = clock();
	selct1(arr, 20);
	end1 = clock();
	start2 = clock();
	selct2(arr, 20);//排序
	end2 = clock();
	for (int k = 0; k < 20; k++) {
		printf("%5.2d\n", arr[k]);
	}//打印数组
	printf("%lf\n%lf\n",end1-start1,end2-start2);
	return 0;

}
