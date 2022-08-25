using System;
using System.Security;

namespace TANSS
{
    /// <summary>
    ///
    /// </summary>
    public class Connection
    {
        /// <summary>
        ///
        /// </summary>
        public string Server;

        /// <summary>
        ///
        /// </summary>
        public string UserName;

        /// <summary>
        ///
        /// </summary>
        public int EmployeeId;

        /// <summary>
        ///
        /// </summary>
        public string EmployeeType;

        /// <summary>
        ///
        /// </summary>
        public SecureString AccessToken;

        /// <summary>
        ///
        /// </summary>
        public SecureString RefreshToken;

        /// <summary>
        ///
        /// </summary>
        public string Message;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampCreated;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampExpires;

        /// <summary>
        ///
        /// </summary>
        public DateTime TimeStampModified;

        /// <summary>
        /// Whether the token is valid for connections
        /// </summary>
        public bool IsValid {
            get {
                if(TimeStampExpires < DateTime.Now)
                    return false;
                if(TimeStampExpires == null)
                    return false;
                if(AccessToken == null)
                    return false;
                return true;
            }

            set {
            }
        }

        /// <summary>
        /// The Lifetime of the Access Token
        /// </summary>
        public TimeSpan AccessTokenLifeTime {
            get {
                return TimeStampExpires.Subtract(TimeStampCreated);
            }

            set {
            }
        }

        /// <summary>
        /// Remaining time of the token Lifetime
        /// </summary>
        public TimeSpan TimeRemaining {
            get {
                if(TimeStampExpires > DateTime.Now) {
                    TimeSpan timeSpan = TimeStampExpires - DateTime.Now;
                    return TimeSpan.Parse(timeSpan.ToString(@"dd\.hh\:mm\:ss"));
                } else {
                    TimeSpan timeSpan = TimeSpan.Parse("0:0:0:0");
                    return timeSpan;
                }
            }

            set {
            }
        }

        /// <summary>
        /// Percentage value of the Tokenlifetime
        /// </summary>
        public Int16 PercentRemaining {
            get {
                if(TimeStampExpires > DateTime.Now) {
                    Int16 percentage = (Int16)(Math.Round(TimeRemaining.TotalMilliseconds / AccessTokenLifeTime.TotalMilliseconds * 100, 0));
                    return percentage;
                } else {
                    return 0;
                }
            }

            set {
            }
        }


    }
}
