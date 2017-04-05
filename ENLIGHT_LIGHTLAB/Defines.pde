//scopes
public static final int STUDIO   = 0;
public static final int MEETING1 = 1;
public static final int MEETING2 = 2;
public static final int MEETING3 = 3;
public static final int OFFICE   = 4;
public static final int FLEX     = 5;
public static final int CORRIDOR = 6;

public String getScopeName(int value)
{
  if (value == 0) return "STUDIO";
  if (value >=1 && value <= 3) return "MEETING"+value;
  if (value == 4) return "OFFICE";
  if (value == 5) return "FLEX";
  if (value == 6) return "CORRIDOR";
  
  return "NO_SCOPE";
}


//levels
public static final int LVL_BACKGROUND = 1;
public static final int LVL_WORK = 2;

//addresses
public static final String ADDRESS_PC       = "01:02:03:04:05:06:07:00";
public static final String PC_ADDRESS       = ADDRESS_PC;
public static final String ADDRESS_LVL      = "01:02:03:04:05:06:07:0";
public static final String ADDRESS_INTERNAL = "00:00:00:00:00:00:00:00";

public static final int TILE = 50;

boolean POWERON = true;