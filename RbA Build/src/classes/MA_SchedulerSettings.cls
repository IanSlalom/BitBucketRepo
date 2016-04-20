public with sharing class MA_SchedulerSettings {
	
	public static void consumeObject(JSONParser parser) {
		Integer depth = 0;
		do {
			JSONToken curr = parser.getCurrentToken();
			if (curr == JSONToken.START_OBJECT || 
				curr == JSONToken.START_ARRAY) {
				depth++;
			} else if (curr == JSONToken.END_OBJECT ||
				curr == JSONToken.END_ARRAY) {
				depth--;
			}
		} while (depth > 0 && parser.nextToken() != null);
	}

	public class Tech_Measure {
		public String jobDuration {get;set;} 
		public String crewSize {get;set;} 
		public BookingWindows bookingWindows {get;set;} 

		public Tech_Measure(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'jobDuration') {
							jobDuration = parser.getText();
						} else if (text == 'crewSize') {
							crewSize = parser.getText();
						} else if (text == 'bookingWindows') {
							bookingWindows = new BookingWindows(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Tech Measure consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class StoreHours {
		public List<dayHours> monday {get;set;} 
		public List<dayHours> tuesday {get;set;} 
		public List<dayHours> wednesday {get;set;} 
		public List<dayHours> thursday {get;set;} 
		public List<dayHours> friday {get;set;} 
		public List<dayHours> saturday {get;set;}
		public List<dayHours> sunday {get;set;} 

		public StoreHours(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'monday') {
							monday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								monday.add(new dayHours(parser));
							}
						} else if (text == 'tuesday') {
							tuesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								tuesday.add(new dayHours(parser));
							}
						} else if (text == 'wednesday') {
							wednesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								wednesday.add(new dayHours(parser));
							}
						} else if (text == 'thursday') {
							thursday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								thursday.add(new dayHours(parser));
							}
						} else if (text == 'friday') {
							friday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								friday.add(new dayHours(parser));
							}
						} else if (text == 'saturday') {
							saturday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								saturday.add(new dayHours(parser));
							}
						} else if (text == 'sunday') {
							sunday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								sunday.add(new dayHours(parser));
							}
						} else {
							System.debug(LoggingLevel.WARN, 'StoreHours consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class dayHours {
		public String start {get;set;} 
		public String end_Z {get;set;} // in json: end

		public dayHours(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'start') {
							start = parser.getText();
						} else if (text == 'end') {
							end_Z = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'dayHours consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public String timezone {get;set;} 
	public StoreHours storeHours {get;set;} 
	public Tech_Measure Tech_Measure {get;set;} 
	public Install Install {get;set;} 
	public Service Service {get;set;} 
	public ResourceHours resourceHours {get;set;}

	public MA_SchedulerSettings(JSONParser parser) {
		while (parser.nextToken() != JSONToken.END_OBJECT) {
			if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
				String text = parser.getText();
				if (parser.nextToken() != JSONToken.VALUE_NULL) {
					if (text == 'timezone') {
						timezone = parser.getText();
					} else if (text == 'storeHours') {
						storeHours = new StoreHours(parser);
					} else if (text == 'Tech Measure') {
						Tech_Measure = new Tech_Measure(parser);
					} else if (text == 'Install') {
						Install = new Install(parser);
					} else if (text == 'Service') {
						Service = new Service(parser);
					}else if (text == 'resourceHours') {
						resourceHours = new ResourceHours(parser);
					} else {
						System.debug(LoggingLevel.WARN, 'Root consuming unrecognized property: '+text);
						consumeObject(parser);
					}
				}
			}
		}
	}
	
	public class BookingWindows_Z {
		public List<dayHours> monday {get;set;} 
		public List<dayHours> tuesday {get;set;} 
		public List<dayHours> wednesday {get;set;} 
		public List<dayHours> thursday {get;set;} 
		public List<dayHours> friday {get;set;} 
		public List<dayHours> saturday {get;set;} 
		public List<dayHours> sunday {get;set;} 

		public BookingWindows_Z(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'monday') {
							monday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								monday.add(new dayHours(parser));
							}
						} else if (text == 'tuesday') {
							tuesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								tuesday.add(new dayHours(parser));
							}
						} else if (text == 'wednesday') {
							wednesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								wednesday.add(new dayHours(parser));
							}
						} else if (text == 'thursday') {
							thursday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								thursday.add(new dayHours(parser));
							}
						} else if (text == 'friday') {
							friday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								friday.add(new dayHours(parser));
							}
						} else if (text == 'saturday') {
							saturday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								saturday.add(new dayHours(parser));
							}
						} else if (text == 'sunday') {
							sunday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								sunday.add(new dayHours(parser));
							}
						} else {
							System.debug(LoggingLevel.WARN, 'BookingWindows_Z consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class BookingWindows {
		public List<dayHours> monday {get;set;} 
		public List<dayHours> tuesday {get;set;} 
		public List<dayHours> wednesday {get;set;} 
		public List<dayHours> thursday {get;set;}
		public List<dayHours> friday {get;set;}
		public List<dayHours> saturday {get;set;}
		public List<dayHours> sunday {get;set;} 

		public BookingWindows(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'monday') {
							monday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								monday.add(new dayHours(parser));
							}
						} else if (text == 'tuesday') {
							tuesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								tuesday.add(new dayHours(parser));
							}
						} else if (text == 'wednesday') {
							wednesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								wednesday.add(new dayHours(parser));
							}
						} else if (text == 'thursday') {
							thursday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								thursday.add(new dayHours(parser));
							}
						} else if (text == 'friday') {
							friday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								friday.add(new dayHours(parser));
							}
						} else if (text == 'saturday') {
							saturday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								saturday.add(new dayHours(parser));
							}
						} else if (text == 'sunday') {
							sunday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								sunday.add(new dayHours(parser));
							}
						} else {
							System.debug(LoggingLevel.WARN, 'BookingWindows consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Service {
		public String jobDuration {get;set;} 
		public String crewSize {get;set;} 
		public BookingWindows_Z bookingWindows {get;set;} 

		public Service(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'jobDuration') {
							jobDuration = parser.getText();
						} else if (text == 'crewSize') {
							crewSize = parser.getText();
						} else if (text == 'bookingWindows') {
							bookingWindows = new BookingWindows_Z(parser);
						} else {
							System.debug(LoggingLevel.WARN, 'Service consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	public class Install {
		public String jobDuration {get;set;} 
		public String crewSize {get;set;} 

		public Install(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'jobDuration') {
							jobDuration = parser.getText();
						} else if (text == 'crewSize') {
							crewSize = parser.getText();
						} else {
							System.debug(LoggingLevel.WARN, 'Install consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}

	public class ResourceHours {
		public List<dayHours> monday {get;set;} 
		public List<dayHours> tuesday {get;set;} 
		public List<dayHours> wednesday {get;set;} 
		public List<dayHours> thursday {get;set;} 
		public List<dayHours> friday {get;set;} 
		public List<dayHours> saturday {get;set;} 
		public List<dayHours> sunday {get;set;}

		public ResourceHours(JSONParser parser) {
			while (parser.nextToken() != JSONToken.END_OBJECT) {
				if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
					String text = parser.getText();
					if (parser.nextToken() != JSONToken.VALUE_NULL) {
						if (text == 'monday') {
							monday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								monday.add(new dayHours(parser));
							}
						} else if (text == 'tuesday') {
							tuesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								tuesday.add(new dayHours(parser));
							}
						} else if (text == 'wednesday') {
							wednesday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								wednesday.add(new dayHours(parser));
							}
						} else if (text == 'thursday') {
							thursday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								thursday.add(new dayHours(parser));
							}
						} else if (text == 'friday') {
							friday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								friday.add(new dayHours(parser));
							}
						} else if (text == 'saturday') {
							saturday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								saturday.add(new dayHours(parser));
							}
						} else if (text == 'sunday') {
							sunday = new List<dayHours>();
							while (parser.nextToken() != JSONToken.END_ARRAY) {
								sunday.add(new dayHours(parser));
							}
						} else {
							System.debug(LoggingLevel.WARN, 'ResourceHours consuming unrecognized property: '+text);
							consumeObject(parser);
						}
					}
				}
			}
		}
	}
	
	
	public static MA_SchedulerSettings parse(String json) {
		return new MA_SchedulerSettings(System.JSON.createParser(json));
	}
}