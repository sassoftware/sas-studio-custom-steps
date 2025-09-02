Testing Bugs encountered

The following is more an internal focussed activity (and perhaps won't / needn't be included). To illustrate bugs or errors that came about during a test of this custom step (in the hope that it promotes awareness / learning)

1. os.system is lazy and HUGE potential for errors.  Especially silent ones since you don't know (without additional coding) whether stuff ran or not. Use subprocess instead.