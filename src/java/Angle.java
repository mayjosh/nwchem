public class Angle{

    public double value, force;
    public String type1, type2, type3;
    public int source;
    boolean  redefining, redefined;

    public Angle(String card, int isource){
	source=isource;
	type1=card.substring(0,2);
	type2=card.substring(6,8);
	type3=card.substring(12,14);
	value=Double.valueOf(card.substring(18,27)).doubleValue();
	force=Double.valueOf(card.substring(27,39)).doubleValue();
	redefining=false; redefined=false;
    }

}
