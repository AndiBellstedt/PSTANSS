using System;
using System.Security;
using System.Xml.Linq;

namespace TANSS {
    namespace Vacation {
        /// <summary>
        ///
        /// </summary>
        [Serializable]
        public class Day {
            #region Properties

            /// <summary>
            ///
            /// </summary>
            public DayBaseObject BaseObject;

            /// <summary>
            ///
            /// </summary>
            ///public int VacationRequestId;
            public int VacationRequestId {
                get { return BaseObject.vacationRequestId; }
                set { BaseObject.vacationRequestId = value; }
            }

            /// <summary>
            ///
            /// </summary>
            public DateTime Date {
                get {
                    DateTime dateTime = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
                    dateTime = dateTime.AddSeconds(BaseObject.date).ToLocalTime();
                    return dateTime;
                }
                set {
                    BaseObject.date = (Int32)(value.ToUniversalTime().Subtract(new DateTime(1970, 1, 1))).TotalSeconds;
                }
            }

            /// <summary>
            ///
            /// </summary>
            public bool Forenoon {
                get { return BaseObject.forenoon; }
                set { BaseObject.forenoon = value; }
            }

            /// <summary>
            ///
            /// </summary>
            public bool Afternoon {
                get { return BaseObject.afternoon; }
                set { BaseObject.afternoon = value; }
            }

            /// <summary>
            ///
            /// </summary>
            public DateTime StartTime {
                get {
                    return Date.AddHours(BaseObject.startHour).AddMinutes(BaseObject.startMinute);
                }
                set {
                    BaseObject.startHour = value.Hour;
                    BaseObject.startMinute = value.Minute;
                }
            }

            /// <summary>
            ///
            /// </summary>
            public DateTime EndTime {
                get {
                    return Date.AddHours(BaseObject.endHour).AddMinutes(BaseObject.endMinute);
                }
                set {
                    BaseObject.endHour = value.Hour;
                    BaseObject.endMinute = value.Minute;
                }
            }

            /// <summary>
            ///
            /// </summary>
            public int Pause {
                get { return BaseObject.pause; }
                set { BaseObject.pause = value; }
            }

            /// <summary>
            ///
            /// </summary>
            public bool IsFullDay {
                get {
                    if(Forenoon==true && Afternoon==true) {
                        return true;
                    } else {
                        return false;
                    }
                }
            }

            private string _returnValue;

            #endregion Properties


            #region Statics & Stuff
            /// <summary>
            /// Overrides the default ToString() method
            /// </summary>
            /// <returns></returns>
            public override string ToString () {
                if (!string.IsNullOrEmpty( Date.ToString() )) {
                    _returnValue = String.Format("{0:yyyy-MM-dd}", Date);
                    if(IsFullDay == true) {
                        _returnValue = _returnValue + "/FullDay";
                    } else if (Forenoon == true || Afternoon == true) {
                        _returnValue = _returnValue + "/HalfDay";
                    } else if (Forenoon == false || Afternoon == false) {
                        _returnValue = _returnValue + "/None";
                    } else {
                        _returnValue = _returnValue + "/Custom";
                    }
                } else {
                    _returnValue = this.GetType().Name;
                }

                return _returnValue;
            }
            #endregion Statics & Stuff

        }
    }
}