/// Returns the age in full years that [birthDate] has reached at [now].
int ageInYearsAt(DateTime birthDate, DateTime now) {
  var age = now.year - birthDate.year;
  final hadBirthdayThisYear =
      now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!hadBirthdayThisYear) {
    age--;
  }
  return age < 0 ? 0 : age;
}
