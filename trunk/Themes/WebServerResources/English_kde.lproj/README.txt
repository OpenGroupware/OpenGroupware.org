# $Id$


MAPS:
cp nuvolap/apps/kmail.png     menu_email_labeled_inactive.png 
cp nuvolap/apps/kmail.png     menu_email_labeled.png 
cp nuvolap/apps/email.png     menu_email_new_labeled.png 
cp nuvolap/apps/kuser.png     menu_enterprises_labeled.png 
cp nuvolap/apps/kcmsystem.png menu_jobs_labeled.png 
cp nuvolap/apps/browser.png   menu_news_labeled.png 
cp nuvolap/apps/personal.png  menu_persons_labeled.png 
cp nuvolap/apps/designer.png  menu_projects_labeled.png 
cp nuvolap/apps/date.png      menu_scheduler_labeled.png 
cp nuvolap/apps/kig.png       menu_bookmarks_labeled.png
cp nuvolap/apps/kcontrol.png  menu_static_prefs.png

cp nuvolap/32x32/apps/kmail.png     menu_email_labeled_inactive.png 
cp nuvolap/32x32/apps/kmail.png     menu_email_labeled.png 
cp nuvolap/32x32/apps/email.png     menu_email_new_labeled.png 
cp nuvolap/32x32/apps/kuser.png     menu_enterprises_labeled.png 
cp nuvolap/32x32/apps/kcmsystem.png menu_jobs_labeled.png 
cp nuvolap/32x32/apps/browser.png   menu_news_labeled.png 
cp nuvolap/32x32/apps/personal.png  menu_persons_labeled.png 
cp nuvolap/32x32/apps/designer.png  menu_projects_labeled.png 
cp nuvolap/32x32/apps/date.png      menu_scheduler_labeled.png 
cp nuvolap/32x32/apps/kig.png       menu_bookmarks_labeled.png
cp nuvolap/32x32/apps/kcontrol.png  menu_static_prefs.png


New Info
========

WORK IN PROGRESS

Base work on Nuvola LGPL theme by iconking (http://www.icon-king.com/). We
are using the 48x48 images which seem to be the best fit.

menu_news_labeled.gif		=> actions/gohome.png?
menu_persons_labeled.gif	=> apps/personal.png?
menu_enterprises_labeled.gif	=> apps/kaddressbook.png, apps/kuser.png?
menu_projects_labeled.gif	=> apps/kchart.png?, apps/kcmdf.png?
menu_scheduler_labeled.gif	=> apps/date.png
menu_jobs_labeled.gif		=> apps/kedit.png?
menu_email_labeled_inactive.gif	=> apps/email.png?
menu_bookmarks_labeled.gif	=> apps/kblackbox.png?, keditbookmark.png?
admin => apps/kdmconfig.png?, kuser.png?


GIF
===

Yes, this s***, but otherwise we would need to change the templates.

for i in *.png; do
  pngtopnm $i | ppmquant 256 |ppmtogif >`basename $i .png`.gif; 
done

-interlace
-sort
-transparent[=color]
-alpha
-comment "Nuvola"

FILE="index-nuvola.html"
echo "<html><body>" > $FILE
echo "<h3>$PWD</h3>" >> $FILE
for i in *.gif; do
  echo "<img src='$i' alt='$i' />" >> $FILE
done
echo "<h4>PNG</h4>" >> $FILE
for i in *.png; do
  echo "<img src='$i' alt='$i' />" >> $FILE
done
echo "</body></html>" >> $FILE


OLD INFO
========
Theme based on kdeartwork-3.2.1/IconThemes/kdeclasses

TODO: all the mime-icons!
TODO: better icons in kdelibs/pics/crystalsvg?

48x48
kfm.png        => menu_projects, menu_projects4
kmail.png      => menu_email,menu_imap
korganizer.png => menu_scheduler
kpilot.png     => menu_palm
kuser.png      => menu_usermanager
kaddressbook.png => menu_persons, menu_enterprises

menu_news
menu_jobs
menu_preferences
menu_resources
menu_bookmarks
menu_desktop

16x16

// could also use tab_first, tab_last etc
// sort_incr, sort_decrease

1rightarrow.png => next, next_blind
1leftarrow.png  => previous, previous_blind
2leftarrow.png  => first, first_blind
2rightarrow.png => last, last_blind
2downarrow.png  => downward_sorted
2uparrow.png    => upward_sorted
non_sorted

closewindow
