void main() {
    int[] prices = {7,6,4,3,1};
    System.out.println(maxProfit(prices));
}

public int maxProfit (int[] prices) {
    int result = 0;
    int i = 0;
    int j = i+1;
    while(j<prices.length){
        if(prices[i]>prices[j]){
            i=j;
        }else {
            result = Math.max((prices[j] - prices[i]), result);
        }
        j++;
    }
    return result;
}